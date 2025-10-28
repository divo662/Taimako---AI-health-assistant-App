import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

class LocationService extends ChangeNotifier {
  static LocationService? _instance;
  static LocationService get instance => _instance ??= LocationService._();

  LocationService._();

  final SupabaseService _supabaseService = SupabaseService.instance;
  bool _initialized = false;

  /// Initialize the location service
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await _supabaseService.initialize();
      _initialized = true;
    } catch (e) {
      print('Error initializing LocationService: $e');
      _initialized = true; // Mark as initialized even if there's an error
    }
  }

  // Nigerian states data
  static const Map<String, String> _nigerianStates = {
    'ABJ': 'Abuja (FCT)',
    'ABI': 'Abia',
    'ADA': 'Adamawa',
    'AKW': 'Akwa Ibom',
    'ANA': 'Anambra',
    'BAU': 'Bauchi',
    'BAY': 'Bayelsa',
    'BEN': 'Benue',
    'BOR': 'Borno',
    'CRO': 'Cross River',
    'DEL': 'Delta',
    'EBO': 'Ebonyi',
    'EDO': 'Edo',
    'EKI': 'Ekiti',
    'ENU': 'Enugu',
    'GOM': 'Gombe',
    'IMO': 'Imo',
    'JIG': 'Jigawa',
    'KAD': 'Kaduna',
    'KAN': 'Kano',
    'KAT': 'Katsina',
    'KEB': 'Kebbi',
    'KOG': 'Kogi',
    'KWA': 'Kwara',
    'LAG': 'Lagos',
    'NAS': 'Nasarawa',
    'NIG': 'Niger',
    'OGU': 'Ogun',
    'OND': 'Ondo',
    'OSU': 'Osun',
    'OYO': 'Oyo',
    'PLA': 'Plateau',
    'RIV': 'Rivers',
    'SOK': 'Sokoto',
    'TAR': 'Taraba',
    'YOB': 'Yobe',
    'ZAM': 'Zamfara',
  };

  // Sample LGAs for major states (in production, this would come from database)
  static const Map<String, List<String>> _stateLGAs = {
    'LAG': [
      'Agege',
      'Ajeromi-Ifelodun',
      'Alimosho',
      'Amuwo-Odofin',
      'Apapa',
      'Badagry',
      'Epe',
      'Eti-Osa',
      'Ibeju-Lekki',
      'Ifako-Ijaiye',
      'Ikeja',
      'Ikorodu',
      'Kosofe',
      'Lagos Island',
      'Lagos Mainland',
      'Mushin',
      'Ojo',
      'Oshodi-Isolo',
      'Shomolu',
      'Surulere'
    ],
    'KAN': [
      'Ajingi',
      'Albasu',
      'Bagwai',
      'Bebeji',
      'Bichi',
      'Bunkure',
      'Dala',
      'Dambatta',
      'Dawakin Kudu',
      'Dawakin Tofa',
      'Doguwa',
      'Fagge',
      'Gabasawa',
      'Garko',
      'Garun Mallam',
      'Gaya',
      'Gezawa',
      'Gwale',
      'Gwarzo',
      'Kabo',
      'Kano Municipal',
      'Karaye',
      'Kibiya',
      'Kiru',
      'Kumbotso',
      'Kunchi',
      'Kura',
      'Madobi',
      'Makoda',
      'Minjibir',
      'Nasarawa',
      'Rano',
      'Rimin Gado',
      'Rogo',
      'Shanono',
      'Sumaila',
      'Takai',
      'Tarauni',
      'Tofa',
      'Tsanyawa',
      'Tudun Wada',
      'Ungogo',
      'Warawa',
      'Wudil'
    ],
    'ABJ': [
      'Abaji',
      'Bwari',
      'Gwagwalada',
      'Kuje',
      'Kwali',
      'Municipal Area Council'
    ],
    'RIV': [
      'Abua/Odual',
      'Ahoada East',
      'Ahoada West',
      'Akuku-Toru',
      'Andoni',
      'Asari-Toru',
      'Bonny',
      'Degema',
      'Eleme',
      'Emohua',
      'Etche',
      'Gokana',
      'Ikwerre',
      'Khana',
      'Obio/Akpor',
      'Ogba/Egbema/Ndoni',
      'Ogu/Bolo',
      'Okrika',
      'Omuma',
      'Opobo/Nkoro',
      'Oyigbo',
      'Port Harcourt',
      'Tai'
    ],
    'KAD': [
      'Birnin Gwari',
      'Chikun',
      'Giwa',
      'Igabi',
      'Ikara',
      'Jaba',
      'Jema\'a',
      'Kachia',
      'Kaduna North',
      'Kaduna South',
      'Kagarko',
      'Kajuru',
      'Kaura',
      'Kauru',
      'Kubau',
      'Kudan',
      'Lere',
      'Makarfi',
      'Sabon Gari',
      'Sanga',
      'Soba',
      'Zangon Kataf',
      'Zaria'
    ],
    'KAT': [
      'Bakori',
      'Batagarawa',
      'Batsari',
      'Baure',
      'Bindawa',
      'Charanchi',
      'Dandume',
      'Danja',
      'Dan Musa',
      'Dutsin Ma',
      'Faskari',
      'Funtua',
      'Ingawa',
      'Jibia',
      'Kafur',
      'Kaita',
      'Kankara',
      'Kankia',
      'Katsina',
      'Kurfi',
      'Kusada',
      'Mai\'Adua',
      'Mani',
      'Mashi',
      'Matazu',
      'Musawa',
      'Rimi',
      'Sabuwa',
      'Safana',
      'Sandamu',
      'Zango'
    ],
    'KWA': [
      'Asa',
      'Baruten',
      'Edu',
      'Ekiti',
      'Ifelodun',
      'Ilorin East',
      'Ilorin South',
      'Ilorin West',
      'Irepodun',
      'Isin',
      'Kaiama',
      'Moro',
      'Offa',
      'Oke Ero',
      'Oyun',
      'Pategi'
    ],
    'OYO': [
      'Afijio',
      'Akinyele',
      'Atiba',
      'Atisbo',
      'Egbeda',
      'Ibadan North',
      'Ibadan North-East',
      'Ibadan North-West',
      'Ibadan South-East',
      'Ibadan South-West',
      'Ibarapa Central',
      'Ibarapa East',
      'Ibarapa North',
      'Ido',
      'Irepo',
      'Iseyin',
      'Itesiwaju',
      'Iwajowa',
      'Kajola',
      'Lagelu',
      'Ogbomoso North',
      'Ogbomoso South',
      'Ogo Oluwa',
      'Olorunsogo',
      'Oluyole',
      'Ona Ara',
      'Orelope',
      'Ori Ire',
      'Oyo',
      'Oyo East',
      'Saki East',
      'Saki West',
      'Surulere'
    ],
    'OSU': [
      'Atakunmosa East',
      'Atakunmosa West',
      'Aiyedaade',
      'Aiyedire',
      'Boluwaduro',
      'Boripe',
      'Ede North',
      'Ede South',
      'Ife Central',
      'Ife East',
      'Ife North',
      'Ife South',
      'Egbedore',
      'Ejigbo',
      'Ifedayo',
      'Ifelodun',
      'Ila',
      'Ilesa East',
      'Ilesa West',
      'Irepodun',
      'Irewole',
      'Isokan',
      'Iwo',
      'Obokun',
      'Odo Otin',
      'Ola Oluwa',
      'Olorunda',
      'Oriade',
      'Orolu',
      'Osogbo'
    ],
    'OND': [
      'Akoko North-East',
      'Akoko North-West',
      'Akoko South-West',
      'Akoko South-East',
      'Akure North',
      'Akure South',
      'Ese Odo',
      'Idanre',
      'Ifedore',
      'Ilaje',
      'Ile Oluji/Okeigbo',
      'Irele',
      'Odigbo',
      'Okitipupa',
      'Ondo East',
      'Ondo West',
      'Ose',
      'Owo'
    ],
    'OGU': [
      'Abeokuta North',
      'Abeokuta South',
      'Ado-Odo/Ota',
      'Egbado North',
      'Egbado South',
      'Ewekoro',
      'Ifo',
      'Ijebu East',
      'Ijebu North',
      'Ijebu North East',
      'Ijebu Ode',
      'Ikenne',
      'Imeko Afon',
      'Ipokia',
      'Obafemi Owode',
      'Odeda',
      'Odogbolu',
      'Ogun Waterside',
      'Remo North',
      'Shagamu'
    ],
    'EKI': [
      'Ado Ekiti',
      'Efon',
      'Ekiti East',
      'Ekiti South-West',
      'Ekiti West',
      'Emure',
      'Gbonyin',
      'Ido Osi',
      'Ijero',
      'Ikole',
      'Ilejemeje',
      'Irepodun/Ifelodun',
      'Ise/Orun',
      'Moba',
      'Oye'
    ],
    'ENU': [
      'Aninri',
      'Awgu',
      'Enugu East',
      'Enugu North',
      'Enugu South',
      'Ezeagu',
      'Igbo Etiti',
      'Igbo Eze North',
      'Igbo Eze South',
      'Igbo Ukwu',
      'Isi Uzo',
      'Nkanu East',
      'Nkanu West',
      'Nsukka',
      'Oji River',
      'Udi',
      'Uzo Uwani'
    ],
    'ANA': [
      'Aguata',
      'Anambra East',
      'Anambra West',
      'Anaocha',
      'Awka North',
      'Awka South',
      'Ayamelum',
      'Dunukofia',
      'Ekwusigo',
      'Idemili North',
      'Idemili South',
      'Ihiala',
      'Njikoka',
      'Nnewi North',
      'Nnewi South',
      'Ogbaru',
      'Onitsha North',
      'Onitsha South',
      'Orumba North',
      'Orumba South',
      'Oyi'
    ],
    'IMO': [
      'Aboh Mbaise',
      'Ahiazu Mbaise',
      'Ehime Mbano',
      'Ezinihitte',
      'Ideato North',
      'Ideato South',
      'Ihitte/Uboma',
      'Ikeduru',
      'Isiala Mbano',
      'Isu',
      'Mbaitoli',
      'Ngor Okpala',
      'Njaba',
      'Nkwerre',
      'Nwangele',
      'Obowo',
      'Oguta',
      'Ohaji/Egbema',
      'Okigwe',
      'Orlu',
      'Orsu',
      'Oru East',
      'Oru West',
      'Owerri Municipal',
      'Owerri North',
      'Owerri West',
      'Unuimo'
    ],
    'DEL': [
      'Aniocha North',
      'Aniocha South',
      'Bomadi',
      'Burutu',
      'Ethiope East',
      'Ethiope West',
      'Ika North East',
      'Ika South',
      'Isoko North',
      'Isoko South',
      'Ndokwa East',
      'Ndokwa West',
      'Okpe',
      'Oshimili North',
      'Oshimili South',
      'Patani',
      'Sapele',
      'Udu',
      'Ughelli North',
      'Ughelli South',
      'Ukwuani',
      'Uvwie',
      'Warri North',
      'Warri South',
      'Warri South West'
    ],
    'BAY': [
      'Brass',
      'Ekeremor',
      'Kolokuma/Opokuma',
      'Nembe',
      'Ogbia',
      'Sagbama',
      'Southern Ijaw',
      'Yenagoa'
    ],
    'CRO': [
      'Abi',
      'Akamkpa',
      'Akpabuyo',
      'Bakassi',
      'Bekwarra',
      'Biase',
      'Boki',
      'Calabar Municipal',
      'Calabar South',
      'Etung',
      'Ikom',
      'Obanliku',
      'Obubra',
      'Obudu',
      'Odukpani',
      'Ogoja',
      'Yakuur',
      'Yala'
    ],
    'AKW': [
      'Abak',
      'Eastern Obolo',
      'Eket',
      'Ekpenyong',
      'Esit Eket',
      'Essien Udim',
      'Etim Ekpo',
      'Etinan',
      'Ibeno',
      'Ibesikpo Asutan',
      'Ibiono-Ibom',
      'Ika',
      'Ikono',
      'Ikot Abasi',
      'Ini',
      'Itu',
      'Mbo',
      'Mkpat-Enin',
      'Nsit-Atai',
      'Nsit-Ibom',
      'Nsit-Ubium',
      'Obot Akara',
      'Okobo',
      'Onna',
      'Oron',
      'Oruk Anam',
      'Udung-Uko',
      'Ukanafun',
      'Uruan',
      'Urue-Offong/Oruko',
      'Uyo'
    ],
    'ABI': [
      'Aba North',
      'Aba South',
      'Arochukwu',
      'Bende',
      'Ikwuano',
      'Isiala Ngwa North',
      'Isiala Ngwa South',
      'Isuikwuato',
      'Obi Ngwa',
      'Ohafia',
      'Osisioma',
      'Ugwunagbo',
      'Ukwa East',
      'Ukwa West',
      'Umu Nneochi',
      'Umuahia North',
      'Umuahia South'
    ],
    'EBO': [
      'Abakaliki',
      'Afikpo North',
      'Afikpo South',
      'Ebonyi',
      'Ezza North',
      'Ezza South',
      'Ikwo',
      'Ishielu',
      'Ivo',
      'Izzi',
      'Ohaozara',
      'Ohaukwu',
      'Onicha'
    ],
    'EDO': [
      'Akoko-Edo',
      'Egor',
      'Esan Central',
      'Esan North-East',
      'Esan South-East',
      'Esan West',
      'Etsako Central',
      'Etsako East',
      'Etsako West',
      'Igueben',
      'Ikpoba Okha',
      'Oredo',
      'Orhionmwon',
      'Ovia North-East',
      'Ovia South-West',
      'Owan East',
      'Owan West',
      'Uhunmwonde'
    ],
    'BEN': [
      'Ado',
      'Agatu',
      'Apa',
      'Buruku',
      'Gboko',
      'Guma',
      'Gwer East',
      'Gwer West',
      'Katsina-Ala',
      'Konshisha',
      'Kwande',
      'Logo',
      'Makurdi',
      'Obi',
      'Ogbadibo',
      'Ohimini',
      'Oju',
      'Okpokwu',
      'Otukpo',
      'Tarka',
      'Ukum',
      'Ushongo',
      'Vandeikya'
    ],
    'PLA': [
      'Bokkos',
      'Barkin Ladi',
      'Bassa',
      'Jos East',
      'Jos North',
      'Jos South',
      'Kanam',
      'Kanke',
      'Langtang North',
      'Langtang South',
      'Mangu',
      'Mikang',
      'Pankshin',
      'Qua\'an Pan',
      'Riyom',
      'Shendam',
      'Wase'
    ],
    'NAS': [
      'Akwanga',
      'Awe',
      'Doma',
      'Karu',
      'Keana',
      'Keffi',
      'Kokona',
      'Lafia',
      'Nasarawa',
      'Nasarawa Egon',
      'Obi',
      'Toto',
      'Wamba'
    ],
    'NIG': [
      'Agaie',
      'Agwara',
      'Bida',
      'Borgu',
      'Bosso',
      'Chanchaga',
      'Edati',
      'Gbako',
      'Gurara',
      'Katcha',
      'Kontagora',
      'Lapai',
      'Lavun',
      'Magama',
      'Mariga',
      'Mashegu',
      'Mokwa',
      'Moya',
      'Paikoro',
      'Rafi',
      'Rijau',
      'Shiroro',
      'Suleja',
      'Tafa',
      'Wushishi'
    ],
    'KOG': [
      'Adavi',
      'Ajaokuta',
      'Ankpa',
      'Bassa',
      'Dekina',
      'Ibaji',
      'Idah',
      'Igalamela Odolu',
      'Ijumu',
      'Kabba/Bunu',
      'Kogi',
      'Lokoja',
      'Mopa Muro',
      'Ofu',
      'Ogori/Magongo',
      'Okehi',
      'Okene',
      'Olamaboro',
      'Omala',
      'Yagba East',
      'Yagba West'
    ],
    'GOM': [
      'Akko',
      'Balanga',
      'Billiri',
      'Dukku',
      'Funakaye',
      'Gombe',
      'Kaltungo',
      'Kwami',
      'Nafada',
      'Shongom',
      'Yamaltu/Deba'
    ],
    'BAU': [
      'Alkaleri',
      'Bauchi',
      'Bogoro',
      'Damban',
      'Darazo',
      'Dass',
      'Gamawa',
      'Ganjuwa',
      'Giade',
      'Itas/Gadau',
      'Jama\'are',
      'Katagum',
      'Kirfi',
      'Misau',
      'Ningi',
      'Shira',
      'Tafawa Balewa',
      'Toro',
      'Warji',
      'Zaki'
    ],
    'JIG': [
      'Auyo',
      'Babura',
      'Biriniwa',
      'Birnin Kudu',
      'Buji',
      'Dutse',
      'Gagarawa',
      'Garki',
      'Gumel',
      'Guri',
      'Gwaram',
      'Gwiwa',
      'Hadejia',
      'Jahun',
      'Kafin Hausa',
      'Kazaure',
      'Kiri Kasama',
      'Kiyawa',
      'Kaugama',
      'Maigatari',
      'Malam Madori',
      'Miga',
      'Ringim',
      'Roni',
      'Sule Tankarkar',
      'Taura',
      'Yankwashi'
    ],
    'YOB': [
      'Bade',
      'Bursari',
      'Geidam',
      'Gujba',
      'Gulani',
      'Jakusko',
      'Karasuwa',
      'Machina',
      'Nangere',
      'Potiskum',
      'Tarmuwa',
      'Yunusari',
      'Yusufari'
    ],
    'BOR': [
      'Abadam',
      'Askira/Uba',
      'Bama',
      'Bayo',
      'Biu',
      'Chibok',
      'Damboa',
      'Dikwa',
      'Gubio',
      'Guzamala',
      'Gwoza',
      'Hawul',
      'Jere',
      'Kaga',
      'Kala/Balge',
      'Konduga',
      'Kukawa',
      'Kwaya Kusar',
      'Mafa',
      'Magumeri',
      'Maiduguri',
      'Marte',
      'Mobbar',
      'Monguno',
      'Ngala',
      'Nganzai',
      'Shani'
    ],
    'TAR': [
      'Ardo Kola',
      'Bali',
      'Donga',
      'Gashaka',
      'Gassol',
      'Ibi',
      'Jalingo',
      'Karim Lamido',
      'Kurmi',
      'Lau',
      'Sardauna',
      'Takum',
      'Ussa',
      'Wukari',
      'Yorro',
      'Zing'
    ],
    'ADA': [
      'Demsa',
      'Fufure',
      'Ganye',
      'Girei',
      'Gombi',
      'Guyuk',
      'Hong',
      'Jada',
      'Lamurde',
      'Madagali',
      'Maiha',
      'Mayo Belwa',
      'Michika',
      'Mubi North',
      'Mubi South',
      'Numan',
      'Shelleng',
      'Song',
      'Toungo',
      'Yola North',
      'Yola South'
    ],
    'SOK': [
      'Binji',
      'Bodinga',
      'Dange Shuni',
      'Gada',
      'Goronyo',
      'Gudu',
      'Gwadabawa',
      'Illela',
      'Isa',
      'Kebbe',
      'Kware',
      'Rabah',
      'Sabon Birni',
      'Shagari',
      'Silame',
      'Sokoto North',
      'Sokoto South',
      'Tambuwal',
      'Tangaza',
      'Tureta',
      'Wamako',
      'Wurno',
      'Yabo'
    ],
    'KEB': [
      'Aleiro',
      'Arewa Dandi',
      'Argungu',
      'Augie',
      'Bagudo',
      'Bunza',
      'Dandi',
      'Fakai',
      'Gwandu',
      'Jega',
      'Kalgo',
      'Koko/Besse',
      'Maiyama',
      'Ngaski',
      'Sakaba',
      'Shanga',
      'Suru',
      'Wasagu/Danko',
      'Yauri',
      'Zuru'
    ],
    'ZAM': [
      'Anka',
      'Bakura',
      'Birnin Magaji/Kiyaw',
      'Bukkuyum',
      'Bungudu',
      'Gummi',
      'Gusau',
      'Kankara',
      'Maradun',
      'Maru',
      'Talata Mafara',
      'Chafe',
      'Zurmi'
    ],
  };

  /// Get Nigerian states synchronously (from static data)
  List<Map<String, String>> getNigerianStatesSync() {
    return _nigerianStates.entries
        .map((entry) => {
              'code': entry.key,
              'name': entry.value,
            })
        .toList();
  }

  /// Get LGAs for a state synchronously (from static data)
  List<Map<String, String>> getLgasForStateSync(String stateCode) {
    final lgas = _stateLGAs[stateCode];
    if (lgas == null) return [];

    return lgas
        .map((lga) => {
              'code': lga, // Using LGA name as code to match database
              'name': lga,
            })
        .toList();
  }

  /// Get all Nigerian states
  Future<List<String>> getNigerianStates() async {
    try {
      // Try to get from database first
      final response = await _supabaseService.client
          .from('nigerian_states')
          .select('state_name, state_code')
          .order('state_name');

      if (response.isNotEmpty) {
        return (response as List)
            .map((state) => state['state_name'] as String)
            .toList();
      }
    } catch (e) {
      print('Error loading states from database: $e');
    }

    // Fallback to static data
    return _nigerianStates.values.toList();
  }

  /// Get LGAs by state code
  Future<List<String>> getLGAsByState(String stateCode) async {
    try {
      // Try to get from database first
      final response = await _supabaseService.client
          .from('nigerian_lgas')
          .select('lga_name')
          .eq('state_code', stateCode)
          .order('lga_name');

      if (response.isNotEmpty) {
        return (response as List)
            .map((lga) => lga['lga_name'] as String)
            .toList();
      }
    } catch (e) {
      print('Error loading LGAs from database: $e');
    }

    // Fallback to static data
    return _stateLGAs[stateCode] ?? [];
  }

  /// Get state code from state name
  String? getStateCode(String stateName) {
    for (final entry in _nigerianStates.entries) {
      if (entry.value == stateName) {
        return entry.key;
      }
    }
    return null;
  }

  /// Get state name from state code
  String? getStateName(String stateCode) {
    return _nigerianStates[stateCode];
  }

  /// Get location context for predictions
  Future<Map<String, dynamic>> getLocationContext({
    required String stateCode,
    String? lgaCode,
  }) async {
    try {
      // Get state information
      final stateResponse = await _supabaseService.client
          .from('nigerian_states')
          .select('*')
          .eq('state_code', stateCode)
          .single();

      Map<String, dynamic> context = {
        'state_code': stateCode,
        'state_name': stateResponse['state_name'],
        'region': stateResponse['region'],
        'climate_zone': stateResponse['climate_zone'],
        'malaria_endemicity': stateResponse['malaria_endemicity'],
        'healthcare_facilities': stateResponse['healthcare_facilities'],
        'emergency_services': stateResponse['emergency_services'],
      };

      // Get LGA information if provided
      if (lgaCode != null) {
        final lgaResponse = await _supabaseService.client
            .from('nigerian_lgas')
            .select('*')
            .eq('lga_code', lgaCode)
            .single();

        context.addAll({
          'lga_code': lgaCode,
          'lga_name': lgaResponse['lga_name'],
          'population': lgaResponse['population'],
          'urban_rural': lgaResponse['urban_rural'],
          'healthcare_access': lgaResponse['healthcare_access'],
        });
      }

      // Get regional health patterns
      final region = stateResponse['region'];
      final season = _getCurrentSeason();

      final healthPatternsResponse = await _supabaseService.client
          .from('regional_health_patterns')
          .select('*')
          .eq('region', region)
          .eq('season', season)
          .single();

      context.addAll({
        'season': season,
        'common_diseases': healthPatternsResponse['common_diseases'],
        'risk_factors': healthPatternsResponse['risk_factors'],
        'prevention_tips': healthPatternsResponse['prevention_tips'],
        'emergency_contacts': healthPatternsResponse['emergency_contacts'],
      });

      return context;
    } catch (e) {
      print('Error getting location context: $e');
      return {
        'state_code': stateCode,
        'state_name': getStateName(stateCode) ?? 'Unknown',
        'region': 'Unknown',
        'climate_zone': 'Unknown',
        'malaria_endemicity': 'Unknown',
        'season': _getCurrentSeason(),
        'error': 'Failed to load location context',
      };
    }
  }

  /// Get current season based on month
  String _getCurrentSeason() {
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) {
      return 'dry_season';
    } else if (month >= 6 && month <= 9) {
      return 'rainy_season';
    } else if (month >= 10 && month <= 11) {
      return 'harmattan';
    } else {
      return 'dry_season';
    }
  }

  /// Get emergency services for a state
  Future<Map<String, dynamic>> getEmergencyServices(String stateCode) async {
    try {
      final response = await _supabaseService.client
          .from('emergency_service_providers')
          .select('*')
          .eq('state_code', stateCode)
          .order('service_type');

      final services = <String, List<Map<String, dynamic>>>{};

      for (final service in response) {
        final type = service['service_type'] as String;
        if (!services.containsKey(type)) {
          services[type] = [];
        }
        services[type]!.add(service);
      }

      return {
        'state_code': stateCode,
        'services': services,
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error getting emergency services: $e');
      return {
        'state_code': stateCode,
        'services': {},
        'error': 'Failed to load emergency services',
      };
    }
  }

  /// Validate Nigerian phone number
  bool isValidNigerianPhone(String phone) {
    // Remove all non-digit characters
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');

    // Check if it's a valid Nigerian phone number
    if (cleaned.length == 10) {
      // Local number without country code
      return RegExp(r'^[0][789][01]\d{7}$').hasMatch(cleaned);
    } else if (cleaned.length == 13 && cleaned.startsWith('234')) {
      // International format with country code
      return RegExp(r'^234[789][01]\d{8}$').hasMatch(cleaned);
    }

    return false;
  }

  /// Format Nigerian phone number
  String formatNigerianPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');

    if (cleaned.length == 10) {
      return '+234 $cleaned';
    } else if (cleaned.length == 13 && cleaned.startsWith('234')) {
      return '+${cleaned.substring(0, 3)} ${cleaned.substring(3)}';
    }

    return phone;
  }
}
