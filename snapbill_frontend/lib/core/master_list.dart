import '../models/item.dart';

// The FULL list from your original app - ALL PRICES SET TO 0.0
final List<Item> masterInventoryList = [
  // Anaaj (Grains)
  Item(
      id: '101',
      names: ['Chawal', 'Rice', 'चावल', 'तांदूळ'],
      price: 0.0,
      unit: 'kg',
      category: 'Anaaj'),
  Item(
      id: '102',
      names: ['Basmati Chawal', 'Basmati Rice', 'बासमती चावल'],
      price: 0.0,
      unit: 'kg',
      category: 'Anaaj'),
  Item(
      id: '103',
      names: ['Gehun', 'Wheat', 'गेहूँ', 'गहू'],
      price: 0.0,
      unit: 'kg',
      category: 'Anaaj'),
  Item(
      id: '104',
      names: ['Bajra', 'Pearl Millet', 'बाजरा', 'बाजरी'],
      price: 0.0,
      unit: 'kg',
      category: 'Anaaj'),
  Item(
      id: '105',
      names: ['Jowar', 'Sorghum', 'ज्वार'],
      price: 0.0,
      unit: 'kg',
      category: 'Anaaj'),
  Item(
      id: '106',
      names: ['Ragi', 'Nachni', 'Finger millet'],
      price: 0.0,
      unit: 'kg',
      category: 'Anaaj'),
  Item(
      id: '107',
      names: ['Makka', 'Corn grain', 'मक्का'],
      price: 0.0,
      unit: 'kg',
      category: 'Anaaj'),
  Item(
      id: '108',
      names: ['Poha', 'Flattened rice', 'पोहा'],
      price: 0.0,
      unit: 'kg',
      category: 'Anaaj'),
  Item(
      id: '109',
      names: ['Bhagar', 'Varai', 'Upvas rice'],
      price: 0.0,
      unit: 'kg',
      category: 'Anaaj'),
  Item(
      id: '110',
      names: ['Sabudana', 'Tapioca Pearls', 'साबूदाना'],
      price: 0.0,
      unit: 'kg',
      category: 'Anaaj'),
  Item(
      id: '111',
      names: ['Suji', 'Rawa', 'Semolina'],
      price: 0.0,
      unit: 'kg',
      category: 'Anaaj'),
  Item(
      id: '112',
      names: ['Daliya', 'Broken Wheat', 'दलिया'],
      price: 0.0,
      unit: 'kg',
      category: 'Anaaj'),

  // Atta (Flour)
  Item(
      id: '201',
      names: ['Gehun ka Atta', 'Wheat Flour', 'आटा'],
      price: 0.0,
      unit: 'kg',
      category: 'Atta'),
  Item(
      id: '202',
      names: ['Maida', 'Refined flour', 'मैदा'],
      price: 0.0,
      unit: 'kg',
      category: 'Atta'),
  Item(
      id: '203',
      names: ['Besan', 'Gram Flour', 'बेसन'],
      price: 0.0,
      unit: 'kg',
      category: 'Atta'),
  Item(
      id: '204',
      names: ['Ragi Atta', 'Nachni flour'],
      price: 0.0,
      unit: 'kg',
      category: 'Atta'),
  Item(
      id: '205',
      names: ['Jowar Atta', 'Sorghum flour'],
      price: 0.0,
      unit: 'kg',
      category: 'Atta'),
  Item(
      id: '206',
      names: ['Bajra Atta', 'Millet flour'],
      price: 0.0,
      unit: 'kg',
      category: 'Atta'),
  Item(
      id: '207',
      names: ['Rice Flour', 'Chawal ka atta'],
      price: 0.0,
      unit: 'kg',
      category: 'Atta'),
  Item(
      id: '208',
      names: ['Makki ka Atta', 'Corn flour'],
      price: 0.0,
      unit: 'kg',
      category: 'Atta'),

  // Dal (Pulses)
  Item(
      id: '301',
      names: ['Toor Dal', 'Arhar Dal', 'Pigeon pea'],
      price: 0.0,
      unit: 'kg',
      category: 'Dal'),
  Item(
      id: '302',
      names: ['Moong Dal', 'Split green gram'],
      price: 0.0,
      unit: 'kg',
      category: 'Dal'),
  Item(
      id: '303',
      names: ['Moong Sabut', 'Whole green gram'],
      price: 0.0,
      unit: 'kg',
      category: 'Dal'),
  Item(
      id: '304',
      names: ['Chana Dal', 'Bengal gram'],
      price: 0.0,
      unit: 'kg',
      category: 'Dal'),
  Item(
      id: '305',
      names: ['Kala Chana', 'Black chickpea'],
      price: 0.0,
      unit: 'kg',
      category: 'Dal'),
  Item(
      id: '306',
      names: ['Kabuli Chana', 'White chickpea', 'छोले'],
      price: 0.0,
      unit: 'kg',
      category: 'Dal'),
  Item(
      id: '307',
      names: ['Masoor Dal', 'Red lentil'],
      price: 0.0,
      unit: 'kg',
      category: 'Dal'),
  Item(
      id: '308',
      names: ['Urad Dal', 'Black gram'],
      price: 0.0,
      unit: 'kg',
      category: 'Dal'),
  Item(
      id: '309',
      names: ['Rajma Lal', 'Red kidney beans'],
      price: 0.0,
      unit: 'kg',
      category: 'Dal'),
  Item(
      id: '310',
      names: ['Rajma Chitra', 'Speckled kidney beans'],
      price: 0.0,
      unit: 'kg',
      category: 'Dal'),
  Item(
      id: '311',
      names: ['Matki', 'Moth', 'Dew beans'],
      price: 0.0,
      unit: 'kg',
      category: 'Dal'),
  Item(
      id: '312',
      names: ['Kulthi', 'Horse gram'],
      price: 0.0,
      unit: 'kg',
      category: 'Dal'),
  Item(
      id: '313',
      names: ['Lobiya', 'Black eyed beans'],
      price: 0.0,
      unit: 'kg',
      category: 'Dal'),

  // Oils (Tel)
  Item(
      id: '401',
      names: ['Sunflower Oil', 'Surajmukhi tel'],
      price: 0.0,
      unit: 'litre',
      category: 'Tel'),
  Item(
      id: '402',
      names: ['Mustard Oil', 'Sarson tel'],
      price: 0.0,
      unit: 'litre',
      category: 'Tel'),
  Item(
      id: '403',
      names: ['Groundnut Oil', 'Mungfali oil'],
      price: 0.0,
      unit: 'litre',
      category: 'Tel'),
  Item(
      id: '404',
      names: ['Coconut Oil', 'Nariyal tel'],
      price: 0.0,
      unit: 'litre',
      category: 'Tel'),
  Item(
      id: '405',
      names: ['Soybean Oil', 'Soya oil'],
      price: 0.0,
      unit: 'litre',
      category: 'Tel'),

  // Spices (Masale)
  Item(
      id: '501',
      names: ['Haldi', 'Turmeric'],
      price: 0.0,
      unit: 'kg',
      category: 'Masale'),
  Item(
      id: '502',
      names: ['Mirch Powder', 'Red chilli powder'],
      price: 0.0,
      unit: 'kg',
      category: 'Masale'),
  Item(
      id: '503',
      names: ['Dhaniya Powder', 'Coriander powder'],
      price: 0.0,
      unit: 'kg',
      category: 'Masale'),
  Item(
      id: '504',
      names: ['Jeera', 'Cumin'],
      price: 0.0,
      unit: 'kg',
      category: 'Masale'),
  Item(
      id: '505',
      names: ['Rai', 'Sarson'],
      price: 0.0,
      unit: 'kg',
      category: 'Masale'),
  Item(
      id: '506',
      names: ['Ajwain', 'Carom seeds'],
      price: 0.0,
      unit: '100g',
      category: 'Masale'),
  Item(
      id: '507',
      names: ['Elaichi', 'Cardamom'],
      price: 0.0,
      unit: '100g',
      category: 'Masale'),
  Item(
      id: '508',
      names: ['Tej Patta', 'Bay leaf'],
      price: 0.0,
      unit: '50g',
      category: 'Masale'),
  Item(
      id: '509',
      names: ['Dalchini', 'Cinnamon'],
      price: 0.0,
      unit: '100g',
      category: 'Masale'),
  Item(
      id: '510',
      names: ['Kalimirch', 'Black pepper'],
      price: 0.0,
      unit: '100g',
      category: 'Masale'),
  Item(
      id: '511',
      names: ['Hing', 'Asafoetida'],
      price: 0.0,
      unit: '50g',
      category: 'Masale'),

  // Dry Fruits
  Item(
      id: '601',
      names: ['Badam', 'Almonds'],
      price: 0.0,
      unit: 'kg',
      category: 'Dry Fruits'),
  Item(
      id: '602',
      names: ['Kaju', 'Cashews'],
      price: 0.0,
      unit: 'kg',
      category: 'Dry Fruits'),
  Item(
      id: '603',
      names: ['Pista', 'Pistachios'],
      price: 0.0,
      unit: 'kg',
      category: 'Dry Fruits'),
  Item(
      id: '604',
      names: ['Kishmish', 'Raisins'],
      price: 0.0,
      unit: 'kg',
      category: 'Dry Fruits'),
  Item(
      id: '605',
      names: ['Khajoor', 'Dates'],
      price: 0.0,
      unit: 'kg',
      category: 'Dry Fruits'),

  // Upvas
  Item(
      id: '701',
      names: ['Bhagar', 'Varai rice'],
      price: 0.0,
      unit: 'kg',
      category: 'Upvas'),
  Item(
      id: '702',
      names: ['Sabudana', 'Tapioca'],
      price: 0.0,
      unit: 'kg',
      category: 'Upvas'),
  Item(
      id: '703',
      names: ['Singhada Atta', 'Water chestnut flour'],
      price: 0.0,
      unit: 'kg',
      category: 'Upvas'),
  Item(
      id: '704',
      names: ['Rajgira Atta', 'Amaranth flour'],
      price: 0.0,
      unit: 'kg',
      category: 'Upvas'),
  Item(
      id: '705',
      names: ['Sendha Namak', 'Rock salt'],
      price: 0.0,
      unit: 'kg',
      category: 'Upvas'),

  // Other / Fast Food
  Item(
      id: '801',
      names: ['Chini', 'Sugar'],
      price: 0.0,
      unit: 'kg',
      category: 'Other'),
  Item(
      id: '802',
      names: ['Tata Namak', 'Iodised Salt'],
      price: 0.0,
      unit: 'kg',
      category: 'Other'),
  Item(
      id: '803',
      names: ['Sendha Namak', 'Rock Salt'],
      price: 0.0,
      unit: 'kg',
      category: 'Other'),
  Item(
      id: '804',
      names: ['Gur', 'Jaggery'],
      price: 0.0,
      unit: 'kg',
      category: 'Other'),
  Item(
      id: '805',
      names: ['Samosa'],
      price: 0.0,
      unit: 'plate',
      category: 'Fast Food'),
  Item(
      id: '806',
      names: ['Namkeen'],
      price: 0.0,
      unit: '250gm',
      category: 'Snacks'),
  Item(
      id: '807',
      names: ['Tea', 'Chai'],
      price: 0.0,
      unit: 'cup',
      category: 'Beverages'),
  Item(
      id: '808',
      names: ['Coffee'],
      price: 0.0,
      unit: 'cup',
      category: 'Beverages'),
];

// Frequent List (Shortcuts) - Also set to 0.0
final List<Item> masterFrequentList = [
  Item(
      id: 'FB1',
      names: ['Samosa'],
      price: 0.0,
      unit: 'plate',
      category: 'Fast Food'),
  Item(
      id: 'FB2',
      names: ['Namkeen'],
      price: 0.0,
      unit: '250gm',
      category: 'Snacks'),
  Item(
      id: 'FB3',
      names: ['Tea', 'Chai'],
      price: 0.0,
      unit: 'cup',
      category: 'Beverages'),
  Item(
      id: 'FB4',
      names: ['Coffee'],
      price: 0.0,
      unit: 'cup',
      category: 'Beverages'),
  Item(
      id: 'FB5',
      names: ['Kachori'],
      price: 0.0,
      unit: 'plate',
      category: 'Fast Food'),
  Item(
      id: 'FB6', names: ['Chips'], price: 0.0, unit: 'pkt', category: 'Snacks'),
  Item(
      id: 'FB7',
      names: ['Coke 2L'],
      price: 0.0,
      unit: 'bottle',
      category: 'Beverages'),
  Item(
      id: 'FB8',
      names: ['Sprite 1L'],
      price: 0.0,
      unit: 'bottle',
      category: 'Beverages'),
];


