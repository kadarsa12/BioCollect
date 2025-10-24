import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../screens/excel_templates_screen.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configurações'),
        backgroundColor: Color(0xFF8D6E63),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // ===== CONTA E LOGIN =====
          _buildSectionCard(
            context,
            'Conta e Login',
            Icons.lock,
            [
              _buildSettingsTile(
                context,
                'Fazer Login',
                'Conectar à API do BioCollect',
                Icons.login,
                    () => _abrirLoginDialog(context),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
              ),
              _buildSettingsTile(
                context,
                'Sair',
                'Encerrar sessão atual',
                Icons.logout,
                    () => _logout(context),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ],
          ),

          SizedBox(height: 16),

          // ===== EXCEL E EXPORTAÇÃO =====
          _buildSectionCard(
            context,
            'Excel e Exportação',
            Icons.table_chart,
            [
              _buildSettingsTile(
                context,
                'Templates Excel',
                'Personalizar colunas de exportação',
                Icons.table_view,
                    () => _openTemplatesScreen(context),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ],
          ),

          SizedBox(height: 16),

          // ===== SINCRONIZAÇÃO =====
          _buildSectionCard(
            context,
            'Sincronização',
            Icons.sync,
            [
              _buildSettingsTile(
                context,
                'Testar Conexão',
                'Verificar conectividade com servidor',
                Icons.wifi_tethering,
                    () => _testarConexao(context),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
              ),
              _buildSettingsTile(
                context,
                'Sincronizar Projeto',
                'Enviar dados para análise',
                Icons.cloud_sync,
                    () => _sincronizarProjeto(context),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
              ),
              _buildSettingsTile(
                context,
                'Ver Resultados',
                'Índices e gráficos gerados',
                Icons.analytics,
                    () => _verResultados(context),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ],
          ),

          SizedBox(height: 16),

          // ===== SOBRE =====
          _buildSectionCard(
            context,
            'Sobre',
            Icons.info,
            [
              _buildSettingsTile(
                context,
                'Sobre o BioCollect',
                'Versão 1.0.0',
                Icons.science,
                    () => _showAboutDialog(context),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ],
          ),

          SizedBox(height: 32),
          Center(
            child: Text(
              'BioCollect v1.0.0',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Widgets base ----------
  Widget _buildSectionCard(BuildContext context, String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF8D6E63).withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Color(0xFF8D6E63)),
                SizedBox(width: 12),
                Text(title,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8D6E63))),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
      BuildContext context,
      String title,
      String subtitle,
      IconData icon,
      VoidCallback onTap, {
        Widget? trailing,
      }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Color(0xFF8D6E63).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Color(0xFF8D6E63), size: 20),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      trailing: trailing,
      onTap: onTap,
    );
  }

  // ---------- Ações ----------
  void _openTemplatesScreen(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ExcelTemplatesScreen()));
  }

  Future<void> _testarConexao(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: const [CircularProgressIndicator(), SizedBox(width: 16), Text('Testando conexão...')],
        ),
      ),
    );

    try {
      final conectado = await ApiService.testarConexao();
      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Row(
            children: [
              Icon(conectado ? Icons.check_circle : Icons.error,
                  color: conectado ? Colors.green : Colors.red),
              SizedBox(width: 8),
              Text(conectado ? 'Conexão OK' : 'Sem Conexão'),
            ],
          ),
          content: Text(conectado
              ? 'Servidor Python conectado com sucesso!'
              : 'Não foi possível conectar ao servidor.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      _showError(context, 'Erro ao testar conexão: $e');
    }
  }

  void _sincronizarProjeto(BuildContext context) {
    _showComingSoon(context);
  }

  void _verResultados(BuildContext context) {
    _showComingSoon(context);
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(children: [
          Icon(Icons.science, color: Color(0xFF8D6E63)),
          SizedBox(width: 8),
          Text('Sobre o BioCollect'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Aplicativo para coleta de dados biológicos.'),
            SizedBox(height: 8),
            Text('Versão: 1.0.0'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Fechar'))],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Funcionalidade em desenvolvimento 🚧'), backgroundColor: Color(0xFF8D6E63)),
    );
  }

  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  // ---------- Login / Logout ----------
  Future<void> _abrirLoginDialog(BuildContext context) async {
    String email = '';
    String senha = '';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(children: const [
          Icon(Icons.login, color: Color(0xFF8D6E63)),
          SizedBox(width: 8),
          Text('Login no BioCollect'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: InputDecoration(labelText: 'E-mail'), onChanged: (v) => email = v),
            TextField(decoration: InputDecoration(labelText: 'Senha'), obscureText: true, onChanged: (v) => senha = v),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _realizarLogin(context, email, senha);
            },
            child: Text('Entrar'),
            style: TextButton.styleFrom(foregroundColor: Color(0xFF8D6E63)),
          ),
        ],
      ),
    );
  }

  Future<void> _realizarLogin(BuildContext context, String email, String senha) async {
    try {
      final token = await ApiService.login(email, senha);
      if (token != null) {
        Provider.of<UserProvider>(context, listen: false).setToken(token);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login realizado com sucesso!'), backgroundColor: Colors.green),
        );
      } else {
        _showError(context, 'Falha no login. Verifique suas credenciais.');
      }
    } catch (e) {
      _showError(context, 'Erro ao fazer login: $e');
    }
  }

  void _logout(BuildContext context) {
    Provider.of<UserProvider>(context, listen: false).logout();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sessão encerrada.'), backgroundColor: Colors.orange),
    );
  }
}
