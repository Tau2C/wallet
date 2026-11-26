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
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212),
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
  bool _pdsAuthorized = false;
  String? _clientId;
  final List<AccountDto> _accounts = [];

  final TextEditingController _accountNameCtrl = TextEditingController(text: 'Konto główne');
  final TextEditingController _currencyCtrl = TextEditingController(text: 'PLN');
  String _selectedType = 'asset';

  @override
  void initState() {
    super.initState();
    _loadCoreVersion();
    _checkPdsStatus();
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

  Future<void> _checkPdsStatus() async {
    try {
      final connected = await _pdsClient.isConnected();
      final authorized = await _pdsClient.isAuthorized();
      final clientId = await _pdsClient.getClientId();
      setState(() {
        _pdsConnected = connected;
        _pdsAuthorized = authorized;
        _clientId = clientId;
      });
    } catch (_) {
      setState(() {
        _pdsConnected = false;
        _pdsAuthorized = false;
      });
    }
  }

  Future<void> _requestPdsAuthorization() async {
    try {
      final result = await _pdsClient.requestAuthorization(
        clientName: 'Wallet',
        permissions: ['ReadEntities', 'WriteEntities', 'ReadBlobs', 'WriteBlobs'],
      );
      if (result.isAuthorized) {
        final clientId = await _pdsClient.getClientId();
        setState(() {
          _pdsAuthorized = true;
          _clientId = clientId;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Autoryzacja udana. ClientId: $clientId')),
          );
        }
        await _connectPds();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Autoryzacja odrzucona przez użytkownika')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd autoryzacji: $e')),
        );
      }
    }
  }

  Future<void> _connectPds() async {
    try {
      final res = await _pdsClient.connect();
      final authorized = await _pdsClient.isAuthorized();
      final clientId = await _pdsClient.getClientId();
      setState(() {
        _pdsConnected = res;
        _pdsAuthorized = authorized;
        _clientId = clientId;
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

  int _selectedTabIndex = 0;

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
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _pdsConnected ? Icons.cloud_done : Icons.cloud_off,
              color: _pdsConnected ? Colors.tealAccent : Colors.grey,
            ),
            tooltip: _pdsConnected ? 'PDS połączone' : 'PDS rozłączone (kliknij by połączyć)',
            onPressed: _connectPds,
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedTabIndex,
        children: [
          _buildAccountsTab(),
          _buildAddAccountTab(),
          _buildStatusTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTabIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Konta',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Nowe konto',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info),
            label: 'Status',
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsTab() {
    if (_accounts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            const Text(
              'Brak zarejestrowanych kont',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Przejdź do zakładki "Nowe konto", aby dodać konto.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _accounts.length,
      itemBuilder: (context, index) {
        final acc = _accounts[index];
        final isAsset = acc.accountType == 'asset';
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isAsset ? Colors.teal.shade900 : Colors.indigo.shade900,
              child: Icon(
                isAsset ? Icons.account_balance_wallet : Icons.credit_card,
                color: Colors.tealAccent,
              ),
            ),
            title: Text(
              acc.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('ID: ${acc.id}\nTyp: ${acc.accountType}'),
            trailing: Chip(
              label: Text(
                acc.currency,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildAddAccountTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Utwórz konto finansowe',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Walidacja reguł księgowych w module Rust Core',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _accountNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nazwa konta',
                  prefixIcon: Icon(Icons.label_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _currencyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Waluta (np. PLN, EUR, USD)',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Typ konta',
                  prefixIcon: Icon(Icons.category_outlined),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'asset', child: Text('Aktywa (Asset)')),
                  DropdownMenuItem(value: 'liability', child: Text('Zobowiązanie (Liability)')),
                  DropdownMenuItem(value: 'equity', child: Text('Kapitał (Equity)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedType = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () async {
                  await _createAccount();
                  if (mounted && _accounts.isNotEmpty) {
                    setState(() {
                      _selectedTabIndex = 0;
                    });
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Utwórz konto'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.memory),
              ),
              title: const Text('Silnik Rust Core'),
              subtitle: Text('Wersja: v$_coreVersion'),
              trailing: const Chip(
                avatar: Icon(Icons.check_circle, size: 16, color: Colors.greenAccent),
                label: Text('Zainicjalizowany'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _pdsAuthorized ? Colors.teal.shade900 : Colors.amber.shade900,
                child: Icon(
                  _pdsAuthorized ? Icons.verified_user : Icons.gpp_maybe,
                  color: _pdsAuthorized ? Colors.tealAccent : Colors.amberAccent,
                ),
              ),
              title: const Text('Autoryzacja PDS Core'),
              subtitle: Text(
                _pdsAuthorized
                    ? 'Autoryzowany (ClientId: ${_clientId ?? "zapisany"})'
                    : 'Brak autoryzacji (wymagane)',
              ),
              trailing: ElevatedButton(
                onPressed: _requestPdsAuthorization,
                child: Text(_pdsAuthorized ? 'Zmień' : 'Autoryzuj'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _pdsConnected ? Colors.teal.shade900 : Colors.grey.shade800,
                child: Icon(
                  _pdsConnected ? Icons.cloud_done : Icons.cloud_off,
                  color: _pdsConnected ? Colors.tealAccent : Colors.grey,
                ),
              ),
              title: const Text('Połączenie PDS Core'),
              subtitle: Text(_pdsConnected ? 'Online (Połączono)' : 'Offline (Rozłączono)'),
              trailing: TextButton(
                onPressed: _connectPds,
                child: Text(_pdsConnected ? 'Odśwież' : 'Połącz'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
