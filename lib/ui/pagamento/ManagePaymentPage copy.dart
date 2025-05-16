import 'dart:convert';

import 'package:app/models/PaymentCriteria.dart';
import 'package:app/models/Reserva.dart';
import 'package:app/models/UserRenderImgBase64.dart';
import 'package:app/services/AtendimentoDocumentService.dart';
import 'package:app/services/AtendimentoItemService.dart';
import 'package:app/services/DetalhePagamentoService.dart';
import 'package:app/services/DetalhesPagamento.dart';
import 'package:app/services/PaymentCriteriaService.dart';
import 'package:app/services/UserAtendimentoAllocationService.dart';
import 'package:app/ui/user/UserDetailsPage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app/services/ReservaService.dart';
import 'package:app/services/UserService.dart';
import 'package:app/services/VeiculoAddService.dart';
import 'package:flutter/material.dart';
import 'package:app/models/Atendimento.dart';
import 'package:app/services/AtendimentoService.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Importe o serviço ManutencaoService
import 'package:app/models/Pagamento.dart';
import 'package:app/models/PagamentoList.dart';
import 'package:app/services/PagamentoService.dart';

class ManagePaymentPage extends StatefulWidget {
  const ManagePaymentPage({super.key});

  @override
  _ManagePaymentPageState createState() => _ManagePaymentPageState();
}

class _ManagePaymentPageState extends State<ManagePaymentPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Payment'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Client in Service'),
              Tab(text: 'Payments'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            const AtendimentosTab(), // Primeira aba: Lista de Atendimentos
            PagamentosTab(),   // Segunda aba: Lista de Pagamentos
          ],
        ),
      ),
    );
  }
}

class AtendimentosTab extends StatefulWidget {
  const AtendimentosTab({super.key});

  @override
  _AtendimentosTabState createState() => _AtendimentosTabState();
}

class _AtendimentosTabState extends State<AtendimentosTab> {
  final AtendimentoService _atendimentoService = AtendimentoService(dotenv.env['BASE_URL']!);
  final ReservaService _reservaService = ReservaService(dotenv.env['BASE_URL']!);
  final VeiculoServiceAdd _veiculoService = VeiculoServiceAdd(dotenv.env['BASE_URL']!);
  final UserService _userService = UserService(dotenv.env['BASE_URL']!);
  final PagamentoService pagamentoService = PagamentoService(dotenv.env['BASE_URL']!);
  final UserAtendimentoAllocationService _userAtendimentoAllocationService = UserAtendimentoAllocationService(baseUrl: dotenv.env['BASE_URL']!);
  final AtendimentoItemService _atendimentoServiceItens = AtendimentoItemService(dotenv.env['BASE_URL']!);
  final AtendimentoDocumentService _atendimentoServiceDocuments = AtendimentoDocumentService(dotenv.env['BASE_URL']!);

  var user, veiculo, state;

  List<Atendimento> _atendimentos = [];
  List<Atendimento> _filteredAtendimentos = [];
  bool _isLoading = false;
  String _searchQuery = '';
  bool _isGridView = true;

  final TextEditingController _destinoController = TextEditingController();
  final TextEditingController _userController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAtendimentos();
  }

  Future<void> _fetchAtendimentos() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      List<Atendimento> atendimentos = await _atendimentoService.fetchAtendimentos();
      List<Atendimento> atendimentosSemPagamento = [];

      for (var atendimento in atendimentos) {
        print('Atendimento ID: ${atendimento.id}, ReserveID: ${atendimento.reservaId}, State: ${atendimento.state}');

        // Verificar se já existe pagamento para este atendimento
        bool temPagamento = await _verificarSeTemPagamento(atendimento.id!);
        if (temPagamento) {
          continue; // Pula para o próximo atendimento se já tiver pagamento
        }

        var reserva = await _reservaService.getReservaById(atendimento.reservaId!);
        user = reserva.user;
        veiculo = reserva.veiculo;
        state = reserva.state;

        // Verificar se tem motoristas alocados
        final motoristas = await _userAtendimentoAllocationService.getUserDetailsByAtendimentoId(atendimento.id!);
        if (motoristas.isNotEmpty) {
          atendimento.userId = reserva.clientId;
          atendimentosSemPagamento.add(atendimento);
        }
      }

      setState(() {
        _atendimentos = atendimentosSemPagamento;
        _filteredAtendimentos = atendimentosSemPagamento;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching atendimentos: $e');
      setState(() => _isLoading = false);
    }
  }

  // Método para verificar se um atendimento já tem pagamento registrado
  Future<bool> _verificarSeTemPagamento(int atendimentoId) async {
    try {
      // Supondo que você tenha um método no PagamentoService para buscar pagamentos por atendimentoId
      final pagamentos = await pagamentoService.fetchPagamentosPorAtendimentoId(atendimentoId);
      return pagamentos.isNotEmpty;
    } catch (e) {
      print('Erro ao verificar pagamentos: $e');
      return false; // Em caso de erro, assumimos que não tem pagamento
    }
  }

  void _filterAtendimentos() {
    String destino = _destinoController.text.toLowerCase();
    String user = _userController.text.toLowerCase();

    setState(() {
      _filteredAtendimentos = _atendimentos.where((atendimento) {
        final atendimentoDestino = atendimento.destino?.toLowerCase() ?? '';
        final atendimentoUser = atendimento.user?.toLowerCase() ?? '';
        return atendimentoDestino.contains(destino) && atendimentoUser.contains(user);
      }).toList();
    });
  }

  Widget _buildSearchFields() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildSearchField(
            controller: _destinoController,
            label: 'Destination',
            icon: Icons.search,
          ),
          const SizedBox(width: 8),
          _buildSearchField(
            controller: _userController,
            label: 'User',
            icon: Icons.person,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return SizedBox(
      width: 200,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        onChanged: (value) => _filterAtendimentos(),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text('No atendimentos found'),
    );
  }

  int _calculateDaysRemaining(DateTime dataChegada) {
    final DateTime now = DateTime.now();
    final Duration difference = dataChegada.difference(now);
    final int daysRemaining = difference.inDays;
    return daysRemaining;
  }

  Widget _buildBlinkingAlert(String message, Color color) {
    return AnimatedBuilder(
      animation: Listenable.merge([ValueNotifier(true)]),
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            message,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }

void _showCreatePagamentoDialog(BuildContext context, int atendimentoId, int userId, int criterioPagamentoId) {
  TextEditingController valorTotalController = TextEditingController();
  TextEditingController dataPagamentoController = TextEditingController();
  PaymentCriteriaService paymentCriteriaService = PaymentCriteriaService(baseUrl: dotenv.env['BASE_URL']!);

  // Variable to store payment criteria
  List<PaymentCriteria> paymentCriteriaList = [];
  PaymentCriteria? selectedPaymentCriteria;

  // Function to load payment criteria
  Future<void> loadPaymentCriteria() async {
    try {
      paymentCriteriaList = await paymentCriteriaService.getAllPaymentCriteria();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading payment criteria: $e')),
      );
    }
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
  return FutureBuilder(
    future: loadPaymentCriteria(),
    builder: (context, snapshot) {
      // Estado de carregamento
      if (snapshot.connectionState == ConnectionState.waiting) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.payment, color: Colors.blue),
              const SizedBox(width: 10),
              Text('Creating Payment', 
                  style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LinearProgressIndicator(),
              const SizedBox(height: 20),
              Text('Loading payment options...', 
                  style: TextStyle(color: Colors.grey[600])),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      }

      // Configura valores iniciais
      if (paymentCriteriaList.isNotEmpty && selectedPaymentCriteria == null) {
        selectedPaymentCriteria = paymentCriteriaList[0];
        valorTotalController.text = paymentCriteriaList[0].amount.toString();
      }

      dataPagamentoController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            title: Row(
              children: [
                const Icon(Icons.payment, color: Colors.blue),
                const SizedBox(width: 10),
                Text('Create Payment', 
                    style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informações do serviço
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 17, 17, 17),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(Icons.confirmation_number, 'Service id:', atendimentoId.toString()),
                        _buildInfoRow(Icons.person, 'User id:', userId.toString()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Campo de valor
                  Text('AMOUNT', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  const SizedBox(height: 5),
                  TextField(
                    controller: valorTotalController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.attach_money),
                      hintText: '0.00',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                    ),
                    onChanged: (value) {
                      if (selectedPaymentCriteria != null && 
                          value != selectedPaymentCriteria!.amount.toString()) {
                        setState(() => selectedPaymentCriteria = null);
                      }
                    },
                  ),
                  const SizedBox(height: 15),
                  
                  // Campo de data
                  Text('PAYMENT DATE', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  const SizedBox(height: 5),
                  TextField(
                    controller: dataPagamentoController,
                    readOnly: true,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      hintText: 'Select date',
                    ),
                    onTap: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Colors.blue,
                                onPrimary: Colors.white,
                                surface: Colors.white,
                                onSurface: Colors.black,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (pickedDate != null) {
                        setState(() {
                          dataPagamentoController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 15),
                  
                  // Critério de pagamento
                  Text('PAYMENT CRITERIA', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  const SizedBox(height: 5),
                  DropdownButtonFormField<PaymentCriteria>(
                    value: selectedPaymentCriteria,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    hint: const Text('Select criteria'),
                    items: paymentCriteriaList.map((criteria) {
                      return DropdownMenuItem<PaymentCriteria>(
                        value: criteria,
                        child: Text(
                          '${criteria.activity} - ${criteria.paymentType} (\$${criteria.amount})',
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedPaymentCriteria = value;
                        if (value != null) {
                          valorTotalController.text = value.amount.toString();
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('CANCEL', style: TextStyle(color: Colors.red)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () async {
                    final valorTotal = double.tryParse(valorTotalController.text.trim());
                    final dataPagamento = dataPagamentoController.text.trim();
                    
                    if (valorTotal == null || valorTotal <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        _buildSnackBar('Please enter a valid amount', Colors.red),
                      );
                      return;
                    }
                    
                    if (dataPagamento.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        _buildSnackBar('Please select a payment date', Colors.red),
                      );
                      return;
                    }
                    
                    if (selectedPaymentCriteria == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        _buildSnackBar('Please select a payment criteria', Colors.red),
                      );
                      return;
                    }
                    
                    try {
                      // Mostrar loading
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(child: CircularProgressIndicator()),
                      );
                      
                      final pagamento = Pagamento(
                        valorTotal: valorTotal,
                        data: DateTime.parse(dataPagamento),
                        atendimentoId: atendimentoId,
                        userId: userId,
                        criterioPagamentoId: selectedPaymentCriteria!.id!,
                      );
                      
                      await pagamentoService.createPagamento(pagamento);
                      
                      Navigator.of(context).pop(); // Fechar loading
                      ScaffoldMessenger.of(context).showSnackBar(
                        _buildSnackBar('Payment created successfully!', Colors.green),
                      );
                      Navigator.of(context).pop(); // Fechar diálogo
                    } catch (e) {
                      Navigator.of(context).pop(); // Fechar loading
                      ScaffoldMessenger.of(context).showSnackBar(
                        _buildSnackBar('Error creating payment: ${e.toString()}', Colors.red),
                      );
                    }
                  },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, size: 18),
                    SizedBox(width: 5),
                    Text('CONFIRM'),
                  ],
                ),
              ),
            ],
          );
        },
      );
      },
    );
  }
);
}

// Widget auxiliar para linhas de informação
Widget _buildInfoRow(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 5),
        Text(value),
      ],
    ),
  );
}

// Widget auxiliar para snackbars
SnackBar _buildSnackBar(String message, Color color) {
  return SnackBar(
    content: Text(message),
    backgroundColor: color,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  );
}

Future<Map<String, dynamic>> _fetchItemsAndDocuments(int atendimentoId) async {
  try {
    final items = await _atendimentoServiceItens.fetchAtendimentoItem(atendimentoId);
    final documents = await _atendimentoServiceDocuments.fetchAtendimentoDocument(atendimentoId);
    return {
      'items': items,
      'documents': documents,
    };
  } catch (e) {
    print('Error fetching items and documents: $e');
    return {
      'items': [],
      'documents': [],
    };
  }
}

Widget _buildItemsAndDocumentsSection(int atendimentoId) {
  return FutureBuilder<Map<String, dynamic>>(
    future: _fetchItemsAndDocuments(atendimentoId),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      
      if (snapshot.hasError) {
        return Text('Error: ${snapshot.error}');
      }
      
      final items = snapshot.data?['items'] ?? [];
      final documents = snapshot.data?['documents'] ?? [];
      
      return Column(
        children: [
          // Seção de Items
          ExpansionTile(
            title: const Text(
              'Listed items',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            children: [
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No items found',
                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.blue[400],
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            item.itemDescription ?? 'No description',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),

          // Seção de Documents
          ExpansionTile(
            title: const Text(
              'Listed Documents',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            children: [
              if (documents.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No documents found',
                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: documents.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final doc = documents[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.blue[400],
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            doc.itemDescription ?? 'No description',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                          trailing: doc.image != null && doc.image!.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.remove_red_eye, color: Colors.blue),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text(doc.itemDescription ?? 'Document Preview'),
                                        content: SingleChildScrollView(
                                          child: InteractiveViewer(
                                            panEnabled: true,
                                            boundaryMargin: const EdgeInsets.all(20),
                                            minScale: 0.5,
                                            maxScale: 4.0,
                                            child: Image.memory(doc.image!),
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(),
                                            child: const Text('Close'),
                                          ),
                                        ],
                                        contentPadding: const EdgeInsets.all(20),
                                        insetPadding: const EdgeInsets.all(20),
                                      ),
                                    );
                                  },
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),

          // Seção para Motoristas Alocados
        ExpansionTile(
        title: const Text(
          'Assigned Drivers',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        children: [
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _userAtendimentoAllocationService.getUserDetailsByAtendimentoId(atendimentoId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Error loading drivers',
                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No drivers assigned',
                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                );
              } else {
                final drivers = snapshot.data!;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: drivers.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final driver = drivers[index];
                      return InkWell(
                        onTap: () {
                          // Converter o Map para UserBase64 e abrir a página de detalhes
                          final user = UserBase64(
                            id: driver['id'],
                            username: driver['email'] ?? '',
                            firstName: driver['nome']?.split(' ').first ?? '',
                            lastName: driver['nome']?.split(' ').length > 1 
                                ? driver['nome']?.split(' ').last ?? ''
                                : '',
                            email: driver['email'] ?? '',
                            phone1: driver['telefone'] ?? '',
                            phone2: driver['telefoneAlternativo'] ?? '',
                            imgBase64: driver['imagem'],
                            gender: driver['gender'] ?? '', // Adicione se disponível
                            birthdate: driver['birthdate'] ?? '',
                            // Outros campos conforme necessário
                          );
                          
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => UserDetailsPage(user: user),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.green[400],
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              driver['nome'] ?? 'No name',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              driver['telefone'] ?? 'No phone',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black,
                              ),
                            ),
                            trailing: driver['imagem'] != null
                                ? CircleAvatar(
                                    backgroundImage: MemoryImage(base64Decode(driver['imagem'])),
                                    radius: 20,
                                  )
                                : const CircleAvatar(
                                    radius: 20,
                                    child: Icon(Icons.person, size: 20),
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }
            },
          ),
        ],
      ),

        ],
      );
    },
  );
}


Widget _buildAtendimentoCard(Atendimento atendimento) {
  final DateTime? dataChegada = atendimento.dataChegada;

  String daysRemainingMessage = 'Data de chegada não disponível';
  Color circleColor = Colors.grey;
  bool isBlinking = false;

  if (dataChegada != null) {
    int daysRemaining = _calculateDaysRemaining(dataChegada);
    if (daysRemaining < 0) {
      daysRemainingMessage = 'Devolução já realizada';
    } else if (daysRemaining <= 5) {
      daysRemainingMessage = 'Faltam $daysRemaining dias para a devolução';
      circleColor = Colors.red;
      isBlinking = true;
    } else if (daysRemaining <= 10) {
      daysRemainingMessage = 'Faltam $daysRemaining dias para a devolução';
      circleColor = Colors.orange;
    } else if (daysRemaining <= 15) {
      daysRemainingMessage = 'Faltam $daysRemaining dias para a devolução';
      circleColor = Colors.yellow;
    } else {
      daysRemainingMessage = 'Faltam mais de 15 dias para a devolução';
      circleColor = Colors.green;
    }
  }

  return Card(
    margin: const EdgeInsets.all(8.0),
    elevation: 4, // Sombra do card
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12), // Bordas arredondadas
    ),
    child: ExpansionTile(
      title: Row(
        children: [
          Icon(
            Icons.car_rental,
            color: circleColor,
          ),
          const SizedBox(width: 8),
          Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Service nr. ${atendimento.id}'
                ', of reservation nr. ${atendimento.reservaId!}' ,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Destination: ${atendimento.destino ?? 'N/A'}',
                style: const TextStyle(fontSize: 14),
              ),
              Text(
                'User: ${user.firstName ?? 'N/A'}',
                style: const TextStyle(fontSize: 14),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () => _showCreatePagamentoDialog(
                      context,
                      atendimento.id!,
                      atendimento.userId!,
                      2, // Critério de pagamento selecionado
                    ),
                    tooltip: 'Confirmar Criação de Pagamento',
                  ),
                ],
              ),
              _buildItemsAndDocumentsSection(atendimento.id!),
            ],
          ),
        ),
        ],
      ),
      trailing: isBlinking
          ? _buildBlinkingAlert(daysRemainingMessage, circleColor)
          : Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: circleColor,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                daysRemainingMessage,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                Icons.date_range,
                'Data de Saída:',
                atendimento.dataSaida != null
                    ? DateFormat('dd/MM/yyyy').format(atendimento.dataSaida!)
                    : 'N/A',
              ),
              _buildDetailRow(
                Icons.date_range,
                'Data da Provável Devolução:',
                atendimento.dataChegada != null
                    ? DateFormat('dd/MM/yyyy').format(atendimento.dataChegada!)
                    : 'N/A',
              ),
              _buildDetailRow(
                Icons.date_range,
                'Data da Devolução:',
                atendimento.dataDevolucao != null
                    ? DateFormat('dd/MM/yyyy').format(atendimento.dataDevolucao!)
                    : 'N/A',
              ),
              _buildDetailRow(Icons.speed, 'Km Inicial:', atendimento.kmInicial?.toString() ?? 'N/A'),
              _buildDetailRow(Icons.speed, 'Km Final:', atendimento.kmFinal?.toString() ?? 'N/A'),
              _buildDetailRow(Icons.person, 'Usuário:', user.firstName ?? 'N/A'),
              _buildDetailRow(Icons.directions_car, 'Veículo:', veiculo.matricula ?? 'N/A'),
              _buildDetailRow(Icons.flag, 'Estado:', state ?? 'N/A'),
            ],
          ),
        ),
      ],
    ),
  );
}

// Método auxiliar para construir uma linha de detalhe
Widget _buildDetailRow(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          '$label $value',
          style: const TextStyle(fontSize: 14),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildSearchFields(),
          ),
          Expanded(
            child: _isLoading
                ? _buildLoadingIndicator()
                : _filteredAtendimentos.isEmpty
                    ? _buildEmptyState()
                    : _isGridView
                        ? GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 16.0,
                              mainAxisSpacing: 16.0,
                            ),
                            itemCount: _filteredAtendimentos.length,
                            itemBuilder: (context, index) {
                              return _buildAtendimentoCard(_filteredAtendimentos[index]);
                            },
                          )
                        : ListView.builder(
                            itemCount: _filteredAtendimentos.length,
                            itemBuilder: (context, index) {
                              return _buildAtendimentoCard(_filteredAtendimentos[index]);
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class PagamentosTab extends StatelessWidget {
  final PagamentoService pagamentoService = PagamentoService(dotenv.env['BASE_URL']!);
  final AtendimentoService atendimentoService = AtendimentoService(dotenv.env['BASE_URL']!);

  // Função para mostrar detalhes do atendimento
  Future<void> _showAtendimentoDetails(BuildContext context, int atendimentoId) async {
    try {
      // Mostra loading enquanto busca os dados
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Busca os detalhes do atendimento
      final atendimento = await atendimentoService.getAtendimentoById(atendimentoId);

      // Fecha o loading
      Navigator.of(context).pop();

      // Mostra os detalhes em um dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Service Details'),
          contentPadding: const EdgeInsets.all(20.0), // Espaçamento interno
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.9, // 90% da largura da tela
                maxHeight: MediaQuery.of(context).size.height * 0.8, // 80% da altura da tela
              ),
              child: ExpansionTile(
                initiallyExpanded: true,
                title: const Text(
                  'Service Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow(Icons.numbers, 'Atendimento:', '${atendimento.id}'),
                        ExpansionTile(
                          title: _buildDetailRow(Icons.numbers, 'Reserva:', '${atendimento.reservaId}'),
                          children: [
                            FutureBuilder<Reserva>(
                              future: ReservaService(dotenv.env['BASE_URL']!).getReservaById(atendimento.reservaId!),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: Center(child: CircularProgressIndicator()),
                                  );
                                } else if (snapshot.hasError) {
                                  return Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Text('Error: ${snapshot.error}'),
                                  );
                                } else if (!snapshot.hasData) {
                                  return const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: Text('No reservation data found'),
                                  );
                                }
                                
                                final reserva = snapshot.data!;
                                return Padding(
                                  padding: const EdgeInsets.only(left: 24.0, right: 12.0, bottom: 12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildDetailRow(Icons.date_range, 'Date:', DateFormat('dd/MM/yyyy').format(reserva.date)),
                                      _buildDetailRow(Icons.place, 'Destination:', reserva.destination),
                                      _buildDetailRow(Icons.confirmation_number, 'Number of Days:', '${reserva.numberOfDays}'),
                                      _buildDetailRow(Icons.payment, 'Payment Status:', reserva.isPaid),
                                      _buildDetailRow(Icons.build, 'Service Status:', reserva.inService),
                                      _buildDetailRow(Icons.verified, 'Confirmation:', reserva.state),
                                      if (reserva.clientId != null)
                                        ExpansionTile(
                                          title: _buildDetailRow(Icons.person, 'Client id:', '${reserva.clientId}'),
                                          children: [
                                            FutureBuilder<dynamic>(
                                              future: UserService(dotenv.env['BASE_URL']!).getUserById(reserva.clientId!),
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState == ConnectionState.waiting) {
                                                  return const Padding(
                                                    padding: EdgeInsets.all(12.0),
                                                    child: Center(child: CircularProgressIndicator()),
                                                  );
                                                } else if (snapshot.hasError) {
                                                  return Padding(
                                                    padding: const EdgeInsets.all(12.0),
                                                    child: Text('Error: ${snapshot.error}'),
                                                  );
                                                } else if (!snapshot.hasData) {
                                                  return const Padding(
                                                    padding: EdgeInsets.all(12.0),
                                                    child: Text('No client data found'),
                                                  );
                                                }
                                                
                                                final client = snapshot.data!;
                                                return Padding(
                                                  padding: const EdgeInsets.only(left: 24.0, right: 12.0, bottom: 12.0),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      _buildDetailRow(Icons.person, 'Nome:', client['firstName'] ?? 'N/A'),
                                                      _buildDetailRow(Icons.email, 'Email:', client['email'] ?? 'N/A'),
                                                      _buildDetailRow(Icons.phone, 'Telefone:', client['phone1'] ?? 'N/A'),
                                                      _buildDetailRow(Icons.location_on, 'Endereço:', client['address'] ?? 'N/A'),
                                                      _buildDetailRow(Icons.calendar_today, 'Data de Nascimento:', 
                                                        client['birthdate'] != null 
                                                          ? DateFormat('dd/MM/yyyy').format(DateTime.parse(client['birthdate'])) 
                                                          : 'N/A'),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      if (reserva.veiculoId != null)
                                        ExpansionTile(
                                          title: _buildDetailRow(Icons.directions_car, 'Vehicle id:', '${reserva.veiculoId}'),
                                          children: [
                                            FutureBuilder<Veiculo>(
                                              future: VeiculoService().getVeiculoById(reserva.veiculoId!),
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState == ConnectionState.waiting) {
                                                  return const Padding(
                                                    padding: EdgeInsets.all(12.0),
                                                    child: Center(child: CircularProgressIndicator()),
                                                  );
                                                } else if (snapshot.hasError) {
                                                  return Padding(
                                                    padding: const EdgeInsets.all(12.0),
                                                    child: Text('Error: ${snapshot.error}'),
                                                  );
                                                } else if (!snapshot.hasData) {
                                                  return const Padding(
                                                    padding: EdgeInsets.all(12.0),
                                                    child: Text('No vehicle data found'),
                                                  );
                                                }
                                                
                                                final veiculo = snapshot.data!;
                                                return Padding(
                                                  padding: const EdgeInsets.only(left: 24.0, right: 12.0, bottom: 12.0),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      _buildDetailRow(Icons.directions_car, 'Matrícula:', veiculo.matricula ?? 'N/A'),
                                                      _buildDetailRow(Icons.branding_watermark, 'Marca:', veiculo.marca ?? 'N/A'),
                                                      _buildDetailRow(Icons.model_training, 'Modelo:', veiculo.modelo ?? 'N/A'),
                                                      _buildDetailRow(Icons.color_lens, 'Cor:', veiculo.cor ?? 'N/A'),
                                                      _buildDetailRow(Icons.confirmation_number, 'Ano:', veiculo.ano?.toString() ?? 'N/A'),
                                                      _buildDetailRow(Icons.star, 'Estado:', veiculo.state ?? 'N/A'),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        _buildDetailRow(Icons.place, 'Destino:', atendimento.destino ?? 'N/A'),
                        _buildDetailRow(
                          Icons.car_rental, 
                          'Veículo:', 
                          atendimento.veiculo != null 
                            ? '${atendimento.matricula ?? 'Sem marca'}' : 'N/A'
                        ),
                        _buildDetailRow(Icons.date_range, 'Data Início:', DateFormat('dd/MM/yyyy HH:mm').format(atendimento.dataSaida!)),
                        if (atendimento.dataChegada != null)
                          _buildDetailRow(Icons.date_range, 'Data Fim:', DateFormat('dd/MM/yyyy HH:mm').format(atendimento.dataChegada!)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Fecha o loading se estiver aberto
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar detalhes: ${e.toString()}')),
      );
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePagamento(BuildContext context, int pagamentoId) async {
    try {
      // Mostra um diálogo de confirmação
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this payment?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        // Mostra um loading enquanto deleta
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );

        await pagamentoService.deletePagamento(pagamentoId);

        // Fecha o loading
        Navigator.of(context).pop();

        // Mostra mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment deleted successfully!')),
        );

        // Atualiza a lista (precisa de um refresh)
        pagamentoService.fetchPagamentos();
        
      }
    } catch (e) {
      // Fecha o loading se estiver aberto
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir pagamento: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PagamentoList>>(
      future: pagamentoService.fetchPagamentos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No pagamentos available.'));
        }
        
        final pagamentosList = snapshot.data!;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 16.0,
            columns: const [
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Valor Total')),
              DataColumn(label: Text('Data')),
              DataColumn(label: Text('Atendimento')),
              DataColumn(label: Text('User ID')),
              DataColumn(label: Text('Driver')),
              DataColumn(label: Text('Critério Pagamento ID')),
              DataColumn(label: Text('Actions')),
            ],
            rows: pagamentosList.asMap().entries.map((entry) {
              final index = entry.key;
              final pagamento = entry.value;

              final color = index % 2 == 0
                  ? const Color.fromARGB(255, 5, 5, 5)
                  : const Color.fromARGB(255, 83, 83, 83);

              return DataRow(
                color: WidgetStateProperty.resolveWith<Color>(
                  (Set<WidgetState> states) => color,
                ),
                cells: [
                  DataCell(Text(pagamento.id.toString())),
                  DataCell(Text(pagamento.valorTotal.toString())),
                  DataCell(Text(pagamento.data.toString())),
                  DataCell(
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: InkWell(
                      onTap: () => _showAtendimentoDetails(context, pagamento.atendimentoId!),
                      borderRadius: BorderRadius.circular(4),
                      hoverColor: Colors.blue.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(pagamento.atendimentoId.toString()),
                            const SizedBox(width: 8),
                            const Icon(Icons.info_outline, 
                              size: 18, 
                              color: Colors.blue,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                  DataCell(Text(pagamento.userId.toString())),
                  DataCell(Text(pagamento.userName.toString())),
                  DataCell(Text(pagamento.criterioPagamentoId.toString())),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deletePagamento(context, pagamento.id!),
                          tooltip: 'Delete payment',
                        ),
                        IconButton(
                          icon: const Icon(Icons.list),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Payment Details'),
                                  content: SizedBox(
                                    width: double.maxFinite,
                                    child: PaymentDetails(pagamentoId: pagamento.id!),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class PaymentDetails extends StatelessWidget {
  final int pagamentoId;
  final DetalhePagamentoService paymentDetailsService = DetalhePagamentoService(dotenv.env['BASE_URL']!);
  final AtendimentoService atendimentoService = AtendimentoService(dotenv.env['BASE_URL']!);
  final PagamentoService pagamentoService = PagamentoService(dotenv.env['BASE_URL']!);

  PaymentDetails({required this.pagamentoId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'General Information'),
                Tab(text: 'Payment Details'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Primeira aba: Informações gerais (Pagamento + Atendimento)
                  FutureBuilder(
                    future: Future.wait([
                      pagamentoService.fetchPagamentoById(pagamentoId),
                      atendimentoService.fetchAtendimentoByPagamentoId(15),
                    ]),
                    builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: Text('No data available'));
                      }

                      final pagamento = snapshot.data![0] as Pagamento;
                      final atendimento = snapshot.data![1] as Atendimento;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Seção de informações do pagamento
                            Card(
                              elevation: 3,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Payment Information',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildInfoRow('Payment ID:', pagamento.id.toString()),
                                    _buildInfoRow('Total Amount:', '\$${pagamento.valorTotal.toStringAsFixed(2)}'),
                                    _buildInfoRow('Payment Date:', DateFormat('MMM dd, yyyy').format(pagamento.data)),
                                    _buildInfoRow('Payment Criteria:', pagamento.criterioPagamentoId.toString()),
                                  ],
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Seção de informações do atendimento
                            Card(
                              elevation: 3,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Service Information',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildInfoRow('Service:', atendimento.id.toString()),
                                    _buildInfoRow('Status:', atendimento.state),
                                    _buildInfoRow('Client:', atendimento.userId.toString()),
                                    // _buildInfoRow('Created At:', DateFormat('MMM dd, yyyy').format(atendimento.destino)),
                                    // Adicione mais campos conforme necessário
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Segunda aba: Detalhes do pagamento
                  FutureBuilder<List<DetalhePagamento>>(
                    future: paymentDetailsService.fetchDetalhesPagamento(pagamentoId: pagamentoId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error loading payment details: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('No payment details available'));
                      }

                      final paymentDetailsList = snapshot.data!;
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columnSpacing: 16.0,
                            columns: const [
                              DataColumn(label: Text('ID')),
                              DataColumn(label: Text('Amount'), numeric: true),
                              DataColumn(label: Text('Payment Date')),
                              DataColumn(label: Text('Method')),
                              DataColumn(label: Text('Status')),
                            ],
                            rows: paymentDetailsList.map((detail) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(detail.id.toString())),
                                  DataCell(Text('\$${detail.valorPagamento.toStringAsFixed(2)}')),
                                  DataCell(Text(DateFormat('MMM dd, yyyy').format(detail.dataPagamento))),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(child: Text(value)),
        ],
      ),
    );
  }
}

  Widget _buildInfoCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(Icons.receipt, 'Total Amount:', '\$1,250.00'),
            _buildInfoRow(Icons.calendar_today, 'Due Date:', 'June 15, 2023'),
            _buildInfoRow(Icons.credit_card, 'Payment Method:', 'Credit Card'),
            _buildInfoRow(Icons.star, 'Status:', 'Pending Payment'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }

// Example PaymentForm class (you should replace with your actual form)
class PaymentForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Processing'),
      ),
      body: const Center(
        child: Text('Payment form implementation would go here'),
      ),
    );
  }
}

class VeiculoService {
  Future<Veiculo> getVeiculoById(int veiculoId) async {
    final response = await http.get(Uri.parse('${dotenv.env['BASE_URL']}/veiculo/$veiculoId'));
    if (response.statusCode == 200) {
      return Veiculo.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load vehicle');
    }
  }
}