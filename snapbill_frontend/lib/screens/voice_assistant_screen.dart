import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/shop_details.dart';
import '../services/api_client.dart';
import '../providers/bill_provider.dart';

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

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen>
    with SingleTickerProviderStateMixin {
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  late AnimationController _pulseController;

  bool _isListening = false;
  String _currentSpeechChunk = "";
  String _aiResponseText = "Tap to Speak";
  Timer? _silenceTimer;
  final ApiClient _apiClient = ApiClient();
  
  // Edit Mode State
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _setupAnimation();
    _initTts();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _silenceTimer?.cancel();
    _flutterTts.stop();
    super.dispose();
  }

  // --- RESTORED: Exact TTS Settings from your previous version ---
  void _initTts() async {
    await _flutterTts.setLanguage("hi-IN");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5); // Slower rate for clarity
    await _flutterTts.awaitSpeakCompletion(
        true); // CRITICAL: Ensures full sentence is spoken
  }

  void _setupAnimation() {
    _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 1),
        lowerBound: 0.8,
        upperBound: 1.2)
      ..repeat(reverse: true);
  }

  void _toggleListening() async {
    if (_isListening) {
      _stopListening();
    } else {
      _pulseController.forward();
      setState(() {
        _isListening = true;
        _aiResponseText = "Listening...";
      });
      _startListening();
    }
  }

  void _startListening() async {
    bool available = await _speech.initialize(
        onError: (val) => debugPrint('STT Error: $val'),
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            // Only restart if we are supposed to be listening and AI is NOT speaking
            if (_isListening) {
              _startListening();
            }
          }
        });

    if (available) {
      _speech.listen(
        onResult: (val) {
          setState(() => _currentSpeechChunk = val.recognizedWords);
          _silenceTimer?.cancel();
          _silenceTimer = Timer(const Duration(seconds: 2), () {
            if (_currentSpeechChunk.trim().isNotEmpty) {
              // Stop listening immediately to prevent interruption
              _speech.stop();
              _processAiRequest(_currentSpeechChunk);
              setState(() => _currentSpeechChunk = "");
            }
          });
        },
        localeId: 'en_IN',
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    _silenceTimer?.cancel();
    _pulseController.stop();
    setState(() => _isListening = false);
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

  // Helper: Format number without .0 for whole numbers
  String _formatNumber(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toString();
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

  @override
  Widget build(BuildContext context) {
    return Consumer<BillProvider>(
      builder: (context, billProvider, child) {
        final currentBill = billProvider.currentBillItems;
        
        return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
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

            // 2. Mic Animation
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              GestureDetector(
                  onTap: _toggleListening,
                  child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Transform.scale(
                            scale: _isListening ? _pulseController.value : 1.0,
                            child: Container(
                                height: 120,
                                width: 120,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _isListening
                                        ? AppColors.primaryGreen
                                        : Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                          color: _isListening
                                              ? AppColors.primaryGreen
                                                  .withOpacity(0.5)
                                              : Colors.black12,
                                          blurRadius: 30,
                                          spreadRadius: 5)
                                    ],
                                    border: Border.all(
                                        color: _isListening
                                            ? Colors.transparent
                                            : Colors.grey.shade300,
                                        width: 2)),
                                child: Icon(
                                    _isListening
                                        ? Icons.graphic_eq
                                        : Icons.mic_none_rounded,
                                    size: 50,
                                    color: _isListening
                                        ? Colors.white
                                        : Colors.black)));
                      })),
              const SizedBox(height: 15),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                      _isListening
                          ? (_currentSpeechChunk.isEmpty
                              ? "Listening..."
                              : _currentSpeechChunk)
                          : "Tap to Speak",
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style:
                          const TextStyle(fontSize: 14, color: Colors.grey))),
              const SizedBox(height: 10),

              // Response Text
              Text(_aiResponseText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ]),

            // 3. Live Bill Container
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                padding: EdgeInsets.only(
                  bottom: _isEditMode ? MediaQuery.of(context).viewInsets.bottom : 0,
                ),
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
                              flex: 2,
                              child: Text("Price",
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
                                          child: TextField(
                                            controller: TextEditingController(text: item['qty_display'])
                                              ..selection = TextSelection.collapsed(offset: item['qty_display'].length),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontSize: 13),
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                                              border: OutlineInputBorder(),
                                            ),
                                            onChanged: (value) => _updateBillItem(index, 'qty_display', value, billProvider),
                                          )),
                                      const SizedBox(width: 4),
                                      Expanded(
                                          flex: 2,
                                          child: TextField(
                                            controller: TextEditingController(text: _formatNumber((item['rate'] as num).toDouble()))
                                              ..selection = TextSelection.collapsed(offset: _formatNumber((item['rate'] as num).toDouble()).length),
                                            textAlign: TextAlign.right,
                                            keyboardType: TextInputType.number,
                                            style: const TextStyle(fontSize: 12),
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                              border: OutlineInputBorder(),
                                              prefixText: '₹',
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
                                          child: Text(item['name'],
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14))),
                                      Expanded(
                                          flex: 1,
                                          child: Text(_formatQuantityDisplay(item['qty_display']),
                                              textAlign: TextAlign.center,
                                              style:
                                                  const TextStyle(fontSize: 13))),
                                      Expanded(
                                          flex: 2,
                                          child: Text("₹${_formatNumber((item['rate'] as num).toDouble())}",
                                              textAlign: TextAlign.right,
                                              style:
                                                  const TextStyle(fontSize: 12))),
                                      Expanded(
                                          flex: 2,
                                          child: Text("₹${_formatNumber((item['total'] as num).toDouble())}",
                                              textAlign: TextAlign.right,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14))),
                                    ]);
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
          ),
        ),
      ),
    );
      },
    );
  }
}
