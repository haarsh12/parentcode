import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/shop_details.dart';
import '../services/api_client.dart';
import '../providers/bill_provider.dart';
import 'bill_share_modal.dart';
import '../widgets/siri_wave_orb.dart';

class VoiceAssistantScreen extends StatefulWidget {
  final ShopDetails shopDetails;
  final Function(Map<String, dynamic>) onBillFinalized;
  final bool isPrinterConnected;
  final VoidCallback togglePrinter;

  const VoiceAssistantScreen({
    super.key,
    required this.shopDetails,
    required this.onBillFinalized,
    required this.isPrinterConnected,
    required this.togglePrinter,
  });

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> {
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  
  // Native audio control
  static const platform = MethodChannel('com.snapbill/audio');

  bool _isListening = false;
  String _accumulatedText = ""; // Accumulated text during session
  String _currentSpeechChunk = ""; // Live chunk
  String _aiResponseText = "Tap to Start";
  double _audioLevel = 0.0; // For animation
  Timer? _audioLevelTimer;
  final ApiClient _apiClient = ApiClient();
  
  // Edit Mode State
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _initTts();
  }

  @override
  void dispose() {
    _speech.stop();
    _flutterTts.stop();
    _audioLevelTimer?.cancel();
    _unmuteSystemSounds();
    super.dispose();
  }

  /// Mute system sounds (beeps)
  Future<void> _muteSystemSounds() async {
    try {
      await platform.invokeMethod('muteSystemSounds');
      debugPrint('🔇 System sounds muted');
    } catch (e) {
      debugPrint('❌ Failed to mute: $e');
    }
  }

  /// Unmute system sounds
  Future<void> _unmuteSystemSounds() async {
    try {
      await platform.invokeMethod('unmuteSystemSounds');
      debugPrint('🔊 System sounds unmuted');
    } catch (e) {
      debugPrint('❌ Failed to unmute: $e');
    }
  }

  void _initTts() async {
    await _flutterTts.setLanguage("hi-IN");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.awaitSpeakCompletion(true);
  }

  /// Manual tap to start/stop listening
  void _toggleListening() async {
    if (_isListening) {
      // Stop and process
      await _stopListeningAndProcess();
    } else {
      // Start listening
      await _startListening();
    }
  }

  /// Start listening session - MANUAL CONTROL ONLY
  Future<void> _startListening() async {
    // Mute system beeps FIRST
    await _muteSystemSounds();
    
    bool available = await _speech.initialize(
      onError: (val) {
        debugPrint('🎤 STT Error: $val');
        // DO NOT auto-restart - just log error
      },
      onStatus: (status) {
        debugPrint('🎤 Status: $status');
        // DO NOT auto-restart - user must manually tap to restart
      },
    );

    if (available) {
      setState(() {
        _isListening = true;
        _accumulatedText = "";
        _currentSpeechChunk = "";
        _aiResponseText = "Listening...";
        _audioLevel = 0.3;
      });

      await _startSpeechRecognition();
      _startAudioLevelAnimation();
      debugPrint('🎙️ Listening started - MANUAL CONTROL ONLY');
    }
  }

  /// Internal speech recognition start
  Future<void> _startSpeechRecognition() async {
    await _speech.listen(
      onResult: _handleSpeechResult,
      listenMode: stt.ListenMode.dictation,
      partialResults: true,
      localeId: 'en_IN',
      cancelOnError: false,
      // CRITICAL: Disable timeouts completely
      listenFor: const Duration(hours: 24), // Effectively infinite
      pauseFor: const Duration(hours: 1),   // Allow very long pauses
    );
  }

  /// Audio level animation for orb
  void _startAudioLevelAnimation() {
    _audioLevelTimer?.cancel();
    
    _audioLevelTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) {
        if (!_isListening) {
          timer.cancel();
          return;
        }
        
        setState(() {
          // Simulate audio level based on speech activity
          if (_currentSpeechChunk.isNotEmpty) {
            _audioLevel = 0.6 + (0.4 * (timer.tick % 10) / 10);
          } else {
            _audioLevel = 0.3 + (0.2 * (timer.tick % 10) / 10);
          }
        });
      },
    );
  }

  /// Handle speech results
  void _handleSpeechResult(result) {
    if (!_isListening) return;

    setState(() {
      _currentSpeechChunk = result.recognizedWords;
    });

    // If final result, accumulate it
    if (result.finalResult && _currentSpeechChunk.isNotEmpty) {
      _accumulatedText += _currentSpeechChunk + ' ';
      setState(() {
        _currentSpeechChunk = '';
      });
      debugPrint('📝 Accumulated: $_accumulatedText');
    }
  }

  /// Stop listening and process accumulated text
  Future<void> _stopListeningAndProcess() async {
    if (!_isListening) return;

    await _speech.stop();
    _audioLevelTimer?.cancel();
    
    // Unmute system sounds
    await _unmuteSystemSounds();

    // Combine all text
    final finalText = (_accumulatedText + ' ' + _currentSpeechChunk).trim();

    setState(() {
      _isListening = false;
      _accumulatedText = '';
      _currentSpeechChunk = '';
      _audioLevel = 0.0;
    });

    debugPrint('🛑 Stopped. Final text: $finalText');

    // Process only if we have text
    if (finalText.isNotEmpty) {
      await _processAiRequest(finalText);
    } else {
      setState(() {
        _aiResponseText = "No speech detected";
      });
    }
  }

  Future<void> _processAiRequest(String text) async {
    try {
      setState(() => _aiResponseText = "Processing...");

      // 1. Call API
      final data = await _apiClient.post('/voice/process', {"text": text});

      // 2. Handle Text Response (Voice)
      String? msg = data['msg'];
      if (msg != null && msg.isNotEmpty) {
        setState(() => _aiResponseText = msg);

        // CRITICAL FIX: await ensures the UI doesn't refresh/interrupt while speaking
        await _flutterTts.speak(msg);
      }

      // 3. Update Bill (Only AFTER voice finishes)
      if (data['type'] == 'BILL') {
        List<dynamic> newItems = data['items'] ?? [];
        // Use BillProvider instead of local state
        final billProvider = Provider.of<BillProvider>(context, listen: false);
        
        debugPrint("🎤 VOICE API returned ${newItems.length} items");
        
        for (var item in newItems) {
          debugPrint("🎤 RAW API ITEM: $item");
          
          // Normalize the item structure to match what printer expects
          final normalizedItem = {
            'name': item['name'] ?? item['en'] ?? item['item_name'] ?? 'Unknown',
            'en': item['en'] ?? item['name'] ?? item['item_name'] ?? 'Unknown',
            'hi': item['hi'] ?? item['name'] ?? item['item_name'] ?? 'Unknown',
            'qty': item['qty']?.toString() ?? item['quantity']?.toString() ?? '1',
            'qty_display': item['qty_display'] ?? '${item['qty'] ?? item['quantity'] ?? '1'}${item['unit'] ?? 'kg'}',
            'rate': (item['rate'] ?? item['price'] ?? item['unit_price'] ?? 0).toDouble(),
            'total': (item['total'] ?? item['line_total'] ?? 0).toDouble(),
            'unit': item['unit'] ?? 'kg',
          };
          
          debugPrint("🎤 NORMALIZED ITEM: $normalizedItem");
          
          billProvider.addBillItem(normalizedItem);
        }
      }

      // 4. Resume Listening (Optional - makes it conversational)
      // Uncomment the line below if you want it to auto-listen after speaking
      // _toggleListening();
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => _aiResponseText = "Server Error");
    }
  }

  void _finalizeBill() async {
    final billProvider = Provider.of<BillProvider>(context, listen: false);
    
    // DEBUG: Check if bill has items
    if (!billProvider.hasBillItems) {
      debugPrint("❌ VOICE BILL: Bill is empty - cannot print");
      return;
    }

    debugPrint("✅ VOICE BILL: Has ${billProvider.currentBillItems.length} items");
    
    // DEBUG: Print each item structure
    for (var item in billProvider.currentBillItems) {
      debugPrint("VOICE ITEM: $item");
    }

    if (!widget.isPrinterConnected) {
      _flutterTts.speak("Printer connected nahi hai"); // Speak warning
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Connect Printer First!"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      widget.togglePrinter();
      return;
    }

    // Speak confirmation
    _flutterTts.speak("Bill print ho raha hai");

    // Get next bill number
    final billNumber = await billProvider.getNextBillNumber();

    // CRITICAL: Create a COPY of items before clearing
    final itemsCopy = List<Map<String, dynamic>>.from(billProvider.currentBillItems);

    final billData = {
      'id': billNumber,
      'date':
          "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}",
      'time': "${DateTime.now().hour}:${DateTime.now().minute}",
      'total': billProvider.billTotal,
      'shopName': widget.shopDetails.shopName,
      'shopAddress': widget.shopDetails.address,
      'shopPhone': widget.shopDetails.phone1,
      'items': itemsCopy,  // Use the copy, not the reference
    };

    debugPrint("✅ VOICE BILL DATA: $billData");
    final itemsList = billData['items'] as List;
    debugPrint("✅ VOICE BILL ITEMS COUNT: ${itemsList.length}");

    widget.onBillFinalized(billData);

    // Clear bill after printing
    billProvider.clearBill();
    setState(() {
      _aiResponseText = "Bill Printed!";
    });
  }

  void _openShareModal(BillProvider billProvider) {
    if (!billProvider.hasBillItems) return;

    // Get current bill items
    final billItems = List<Map<String, dynamic>>.from(billProvider.currentBillItems);
    final totalAmount = billProvider.billTotal;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BillShareModal(
          billItems: billItems,
          totalAmount: totalAmount,
          shopDetails: widget.shopDetails,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  // Helper: Format number without .0 for whole numbers
  String _formatNumber(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toString();
  }
  
  // Helper: Extract numeric quantity from qtyDisplay (e.g., "2kg" -> "2")
  String _extractQuantityNumber(String qtyDisplay) {
    final numericPart = qtyDisplay.replaceAll(RegExp(r'[^0-9.]'), '');
    return numericPart.isEmpty ? '1' : numericPart;
  }
  
  // Helper: Extract unit from qtyDisplay (e.g., "2kg" -> "kg")
  String _extractUnit(String qtyDisplay) {
    final unitPart = qtyDisplay.replaceAll(RegExp(r'[0-9.]'), '').trim();
    return unitPart.isEmpty ? 'kg' : unitPart;
  }
  
  // Helper: Format rate with unit (e.g., rate=30, qtyDisplay="2plt" -> "₹30/plt")
  String _formatRateWithUnit(double rate, String qtyDisplay) {
    final unit = _extractUnit(qtyDisplay);
    return '₹${_formatNumber(rate)}/$unit';
  }

  // Helper: Format quantity display with smart kg/gm conversion
  String _formatQuantityDisplay(String qtyDisplay) {
    // First apply short unit names
    String result = qtyDisplay;
    result = result.replaceAll('dozen', 'doz');
    result = result.replaceAll('plate', 'plt');
    result = result.replaceAll('pieces', 'pic');
    result = result.replaceAll('pics', 'pic');
    result = result.replaceAll('litre', 'lit');
    result = result.replaceAll('liter', 'lit');
    
    // Smart kg/gm conversion
    // Extract number and unit from string like "0.4kg" or "1.2 kg"
    final RegExp kgPattern = RegExp(r'(\d+\.?\d*)\s*kg', caseSensitive: false);
    final match = kgPattern.firstMatch(result);
    
    if (match != null) {
      double kgValue = double.tryParse(match.group(1) ?? '0') ?? 0;
      
      // If < 1kg, convert to grams
      if (kgValue > 0 && kgValue < 1) {
        int grams = (kgValue * 1000).round();
        result = result.replaceFirst(kgPattern, '${grams}gm');
      }
      // If > 1kg but has decimal, convert fully to grams
      else if (kgValue > 1 && kgValue != kgValue.toInt()) {
        int grams = (kgValue * 1000).round();
        result = result.replaceFirst(kgPattern, '${grams}gm');
      }
      // If whole kg, keep as is
    }
    
    // Convert large grams to kg (e.g., 2000gm -> 2kg)
    final RegExp gmPattern = RegExp(r'(\d+)\s*gm', caseSensitive: false);
    final gmMatch = gmPattern.firstMatch(result);
    
    if (gmMatch != null) {
      int gmValue = int.tryParse(gmMatch.group(1) ?? '0') ?? 0;
      if (gmValue >= 1000 && gmValue % 1000 == 0) {
        int kgValue = gmValue ~/ 1000;
        result = result.replaceFirst(gmPattern, '${kgValue}kg');
      }
    }
    
    return result;
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
    if (!_isEditMode) {
      // Close keyboard when exiting edit mode
      FocusScope.of(context).unfocus();
    }
  }

  void _addManualItem(BillProvider billProvider) {
    // Add empty item and enter edit mode
    final newItem = {
      'name': 'New Item',
      'en': 'New Item',
      'hi': 'New Item',
      'qty': '1',
      'qty_display': '1kg',
      'rate': 0.0,
      'total': 0.0,
      'unit': 'kg',
    };
    
    billProvider.addBillItem(newItem);
    
    if (!_isEditMode) {
      setState(() {
        _isEditMode = true;
      });
    }
  }

  void _updateBillItem(int index, String field, String value, BillProvider billProvider) {
    final items = List<Map<String, dynamic>>.from(billProvider.currentBillItems);
    final item = Map<String, dynamic>.from(items[index]);
    
    if (field == 'name') {
      item['name'] = value;
      item['en'] = value;
      item['hi'] = value;
    } else if (field == 'qty_display') {
      item['qty_display'] = value;
      // Extract numeric part for qty field
      final numericQty = value.replaceAll(RegExp(r'[^0-9.]'), '');
      item['qty'] = numericQty;
      // Recalculate total
      final rate = (item['rate'] as num).toDouble();
      final qty = double.tryParse(numericQty) ?? 1.0;
      item['total'] = rate * qty;
    } else if (field == 'rate') {
      final rate = double.tryParse(value) ?? 0.0;
      item['rate'] = rate;
      // Recalculate total
      final qtyStr = item['qty_display'].toString().replaceAll(RegExp(r'[^0-9.]'), '');
      final qty = double.tryParse(qtyStr) ?? 1.0;
      item['total'] = rate * qty;
    }
    
    items[index] = item;
    billProvider.updateBillItems(items);
  }
  
  // Computed total - always derived from items
  double _computeTotal(List<Map<String, dynamic>> items) {
    return items.fold<double>(
      0,
      (sum, item) => sum + ((item['total'] as num?)?.toDouble() ?? 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BillProvider>(
      builder: (context, billProvider, child) {
        final currentBill = billProvider.currentBillItems;
        final grandTotal = _computeTotal(currentBill);
        
        return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 48),
                    Text(widget.shopDetails.shopName,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(
                        icon: Icon(Icons.print,
                            color: widget.isPrinterConnected
                                ? AppColors.printerConnected
                                : AppColors.printerDisconnected),
                        onPressed: widget.togglePrinter),
                  ]),
            ),

            // 2. Siri-Style Voice Orb (hide when in edit mode)
            if (!_isEditMode)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  
                  // Siri Wave Orb
                  SiriWaveOrb(
                    isActive: _isListening,
                    audioLevel: _audioLevel,
                    onTap: _toggleListening,
                    size: 200,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Live Speech Text
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      _isListening
                          ? (_accumulatedText + ' ' + _currentSpeechChunk).trim().isEmpty
                              ? "Listening..."
                              : (_accumulatedText + ' ' + _currentSpeechChunk).trim()
                          : "Tap to Start",
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        height: 1.4,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),

                  // Response Text
                  Text(
                    _aiResponseText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

            // 3. Live Bill Container
            Expanded(
              child: Container(
                margin: EdgeInsets.fromLTRB(16, _isEditMode ? 10 : 20, 16, 16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      const BoxShadow(
                          color: Colors.black12,
                          blurRadius: 20,
                          offset: Offset(0, -5))
                    ]),
                child: Column(
                  children: [
                    // Bill Header
                    Padding(
                        padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Live Bill",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              Row(
                                children: [
                                  TextButton.icon(
                                      onPressed: currentBill.isEmpty ? null : () {
                                        billProvider.clearBill();
                                        if (_isEditMode) {
                                          _toggleEditMode();
                                        }
                                      },
                                      icon: const Icon(Icons.cancel_outlined,
                                          size: 18, color: Colors.red),
                                      label: const Text("Cancel Bill",
                                          style: TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold))),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () {
                                      if (currentBill.isEmpty) {
                                        // Manual Add Mode
                                        _addManualItem(billProvider);
                                      } else {
                                        _toggleEditMode();
                                      }
                                    },
                                    icon: Icon(
                                      currentBill.isEmpty 
                                        ? Icons.add 
                                        : (_isEditMode ? Icons.close : Icons.edit),
                                      size: 20,
                                      color: AppColors.primaryGreen,
                                    ),
                                    style: IconButton.styleFrom(
                                      backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
                                      padding: const EdgeInsets.all(8),
                                    ),
                                  ),
                                ],
                              ),
                            ])),

                    // Column Headers
                    const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                        child: Row(children: [
                          Expanded(
                              flex: 4,
                              child: Text("Item",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.grey))),
                          Expanded(
                              flex: 1,
                              child: Text("Qty",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.grey))),
                          Expanded(
                              flex: 3,
                              child: Text("Rate",
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.grey))),
                          Expanded(
                              flex: 2,
                              child: Text("Total",
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.grey))),
                        ])),
                    const Divider(height: 1),

                    // List Items
                    Expanded(
                        child: currentBill.isEmpty
                            ? const Center(
                                child: Text("Tap + to add items manually\nor say 'Chawal 1kg'",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey)))
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                itemCount: currentBill.length + (_isEditMode ? 1 : 0),
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 16),
                                itemBuilder: (context, index) {
                                  // Add Item Button at the end in Edit Mode
                                  if (_isEditMode && index == currentBill.length) {
                                    return GestureDetector(
                                      onTap: () => _addManualItem(billProvider),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryGreen.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: AppColors.primaryGreen.withOpacity(0.3),
                                            style: BorderStyle.solid,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add, color: AppColors.primaryGreen, size: 20),
                                            SizedBox(width: 8),
                                            Text(
                                              "Add Item",
                                              style: TextStyle(
                                                color: AppColors.primaryGreen,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                  
                                  final item = currentBill[index];
                                  
                                  if (_isEditMode) {
                                    // Editable Mode
                                    return Row(children: [
                                      GestureDetector(
                                          onTap: () => billProvider.removeBillItem(index),
                                          child: Container(
                                              margin:
                                                  const EdgeInsets.only(right: 8),
                                              padding: const EdgeInsets.all(2),
                                              decoration: BoxDecoration(
                                                  color: Colors.red[50],
                                                  shape: BoxShape.circle),
                                              child: const Icon(Icons.remove,
                                                  size: 16, color: Colors.red))),
                                      Expanded(
                                          flex: 4,
                                          child: TextField(
                                            controller: TextEditingController(text: item['name'])
                                              ..selection = TextSelection.collapsed(offset: item['name'].length),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14),
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                              border: OutlineInputBorder(),
                                            ),
                                            onChanged: (value) => _updateBillItem(index, 'name', value, billProvider),
                                          )),
                                      const SizedBox(width: 4),
                                      Expanded(
                                          flex: 1,
                                          child: TextFormField(
                                            initialValue: _extractQuantityNumber(item['qty_display']),
                                            textAlign: TextAlign.center,
                                            keyboardType: TextInputType.number,
                                            style: const TextStyle(fontSize: 13),
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                                              border: OutlineInputBorder(),
                                            ),
                                            onChanged: (value) {
                                              // Update quantity keeping the unit
                                              final unit = _extractUnit(item['qty_display']);
                                              final newQtyDisplay = '$value$unit';
                                              _updateBillItem(index, 'qty_display', newQtyDisplay, billProvider);
                                            },
                                          )),
                                      const SizedBox(width: 4),
                                      Expanded(
                                          flex: 3,
                                          child: TextFormField(
                                            initialValue: _formatNumber((item['rate'] as num).toDouble()),
                                            textAlign: TextAlign.right,
                                            keyboardType: TextInputType.number,
                                            style: const TextStyle(fontSize: 11),
                                            decoration: InputDecoration(
                                              isDense: true,
                                              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                              border: const OutlineInputBorder(),
                                              prefixText: '₹',
                                              suffixText: '/${_extractUnit(item['qty_display'])}',
                                            ),
                                            onChanged: (value) => _updateBillItem(index, 'rate', value, billProvider),
                                          )),
                                      const SizedBox(width: 4),
                                      Expanded(
                                          flex: 2,
                                          child: Text("₹${_formatNumber((item['total'] as num).toDouble())}",
                                              textAlign: TextAlign.right,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14))),
                                    ]);
                                  } else {
                                    // Display Mode
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Row(children: [
                                        GestureDetector(
                                            onTap: () => billProvider.removeBillItem(index),
                                            child: Container(
                                                margin:
                                                    const EdgeInsets.only(right: 8),
                                                padding: const EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                    color: Colors.red[50],
                                                    shape: BoxShape.circle),
                                                child: const Icon(Icons.remove,
                                                    size: 16, color: Colors.red))),
                                        Expanded(
                                            flex: 4,
                                            child: Text(item['name'],
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14))),
                                        Expanded(
                                            flex: 1,
                                            child: Text(_extractQuantityNumber(item['qty_display']),
                                                textAlign: TextAlign.center,
                                                style:
                                                    const TextStyle(fontSize: 13))),
                                        Expanded(
                                            flex: 3,
                                            child: Text(_formatRateWithUnit((item['rate'] as num).toDouble(), item['qty_display']),
                                                textAlign: TextAlign.right,
                                                style:
                                                    const TextStyle(fontSize: 11))),
                                        Expanded(
                                            flex: 2,
                                            child: Text("₹${_formatNumber((item['total'] as num).toDouble())}",
                                                textAlign: TextAlign.right,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14))),
                                      ]),
                                    );
                                  }
                                })),

                    // Footer Total
                    Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(25))),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton.icon(
                                  onPressed: _finalizeBill,
                                  icon: const Icon(Icons.print,
                                      color: Colors.white, size: 20),
                                  label: const Text("PRINT",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      minimumSize: const Size(140, 48))),
                              
                              // Share Icon (Bigger and tilted northeast)
                              Transform.rotate(
                                angle: -0.5, // Tilt northeast (about 30 degrees)
                                child: IconButton(
                                  onPressed: currentBill.isEmpty ? null : () => _openShareModal(billProvider),
                                  icon: Icon(
                                    Icons.send, // Paper plane icon
                                    color: currentBill.isEmpty ? Colors.grey : AppColors.primaryGreen,
                                    size: 28, // Bigger size
                                  ),
                                  style: IconButton.styleFrom(
                                    backgroundColor: currentBill.isEmpty 
                                        ? Colors.grey[200] 
                                        : AppColors.primaryGreen.withOpacity(0.1),
                                    padding: const EdgeInsets.all(12),
                                  ),
                                ),
                              ),
                              
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text("TOTAL",
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w600)),
                                    Text(
                                        "₹${_formatNumber(billProvider.billTotal)}",
                                        style: const TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textBlack)),
                                  ]),
                            ])),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }
}
