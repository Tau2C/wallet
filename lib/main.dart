import 'package:flutter/material.dart';
import 'package:pds_flutter/pds_flutter.dart';
import 'src/rust/api.dart';
import 'src/rust/frb_generated.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  runApp(const WalletApp());
}

class WalletApp extends StatelessWidget {
  const WalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wallet PDS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const WalletHomePage(),
    );
  }
}

class WalletHomePage extends StatefulWidget {
  const WalletHomePage({super.key});

  @override
  State<WalletHomePage> createState() => _WalletHomePageState();
}

class _WalletHomePageState extends State<WalletHomePage> {
  final PdsClient _pdsClient = PdsClient();
  String _coreVersion = 'Ładowanie...';
  bool _pdsConnected = false;
  final List<AccountDto> _accounts = [];

  final TextEditingController _accountNameCtrl = TextEditingController(text: 'Konto główne');
  final TextEditingController _currencyCtrl = TextEditingController(text: 'PLN');
  String _selectedType = 'asset';

  @override
  void initState() {
    super.initState();
    _loadCoreVersion();
    _checkPdsConnection();
  }

  Future<void> _loadCoreVersion() async {
    try {
      final version = await getCoreVersion();
      setState(() {
        _coreVersion = version;
      });
    } catch (e) {
      setState(() {
        _coreVersion = 'Błąd: $e';
      });
    }
  }

  Future<void> _checkPdsConnection() async {
    try {
      final connected = await _pdsClient.isConnected();
      setState(() {
        _pdsConnected = connected;
      });
    } catch (_) {
      setState(() {
        _pdsConnected = false;
      });
    }
  }

  Future<void> _connectPds() async {
    try {
      final res = await _pdsClient.connect();
      setState(() {
        _pdsConnected = res;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd łączenia z PDS Core: $e')),
        );
      }
    }
  }

  Future<void> _createAccount() async {
    final name = _accountNameCtrl.text.trim();
    final currency = _currencyCtrl.text.trim().toUpperCase();

    if (name.isEmpty || currency.isEmpty) return;

    try {
      final acc = await createAccount(
        name: name,
        accountTypeStr: _selectedType,
        currency: currency,
      );
      setState(() {
        _accounts.add(acc);
      });
      _accountNameCtrl.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd tworzenia konta: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _accountNameCtrl.dispose();
    _currencyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet & PDS Core'),
        actions: [
          IconButton(
            icon: Icon(
              _pdsConnected ? Icons.cloud_done : Icons.cloud_off,
              color: _pdsConnected ? Colors.greenAccent : Colors.white70,
            ),
            tooltip: _pdsConnected ? 'PDS połączone' : 'PDS rozłączone (kliknij by połączyć)',
            onPressed: _connectPds,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Silnik Rust (Core): v$_coreVersion',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(_pdsConnected ? 'PDS Online' : 'PDS Offline'),
                      backgroundColor: _pdsConnected ? Colors.green.shade100 : Colors.grey.shade300,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Utwórz konto finansowe (Rust core validation):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _accountNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nazwa konta',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _currencyCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Waluta',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedType,
                  items: const [
                    DropdownMenuItem(value: 'asset', child: Text('Aktywa')),
                    DropdownMenuItem(value: 'liability', child: Text('Zobowiązanie')),
                    DropdownMenuItem(value: 'equity', child: Text('Kapitał')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedType = val;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _createAccount,
              icon: const Icon(Icons.add),
              label: const Text('Dodaj konto'),
            ),
            const Divider(height: 24),
            const Text(
              'Zarejestrowane konta:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _accounts.isEmpty
                  ? const Center(
                      child: Text('Brak kont. Dodaj pierwsze konto powyżej.'),
                    )
                  : ListView.builder(
                      itemCount: _accounts.length,
                      itemBuilder: (context, index) {
                        final acc = _accounts[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: Icon(
                              acc.accountType == 'asset'
                                  ? Icons.account_balance_wallet
                                  : Icons.credit_card,
                              color: Colors.teal,
                            ),
                            title: Text(acc.name),
                            subtitle: Text('ID: ${acc.id}\nTyp: ${acc.accountType}'),
                            trailing: Text(
                              acc.currency,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
