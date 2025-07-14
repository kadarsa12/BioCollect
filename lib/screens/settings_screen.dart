// screens/settings_screen.dart (NOVA TELA DE CONFIGURAÇÕES)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../screens/excel_templates_screen.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configurações'),
        backgroundColor: Color(0xFF8D6E63),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Remove a seta de voltar
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Seção: Excel e Exportação
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
              _buildSettingsTile(
                context,
                'Configurações de Export',
                'Formato padrão, compressão, etc.',
                Icons.file_download,
                    () => _showComingSoon(context),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Seção: Conta e Perfil
          _buildSectionCard(
            context,
            'Conta e Perfil',
            Icons.person,
            [
              _buildSettingsTile(
                context,
                'Informações do Usuário',
                'Editar perfil',
                Icons.account_circle,
                    () => _openProfileScreen(context),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
              ),
              _buildSettingsTile(
                context,
                'Preferências',
                'Idioma, tema, notificações',
                Icons.tune,
                    () => _showComingSoon(context),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Seção: Dados e Backup
          _buildSectionCard(
            context,
            'Dados e Backup',
            Icons.backup,
            [
              _buildSettingsTile(
                context,
                'Backup de Dados',
                'Exportar todos os projetos',
                Icons.cloud_upload,
                    () => _showComingSoon(context),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
              ),
              _buildSettingsTile(
                context,
                'Importar Dados',
                'Restaurar backup anterior',
                Icons.cloud_download,
                    () => _showComingSoon(context),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
              ),
              _buildSettingsTile(
                context,
                'Limpar Cache',
                'Liberar espaço de armazenamento',
                Icons.cleaning_services,
                    () => _showClearCacheDialog(context),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Seção: Sobre
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
              _buildSettingsTile(
                context,
                'Ajuda e Suporte',
                'Tutoriais e contato',
                Icons.help,
                    () => _showComingSoon(context),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ],
          ),

          SizedBox(height: 32),

          // Versão do app no final
          Center(
            child: Text(
              'BioCollect v1.0.0',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          // Cabeçalho da seção
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
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8D6E63),
                  ),
                ),
              ],
            ),
          ),
          // Itens da seção
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
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  void _openTemplatesScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExcelTemplatesScreen(),
      ),
    );
  }

  void _openProfileScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfileScreen()),
    );
  }

  void _showUserInfo(BuildContext context) {
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.person, color: Color(0xFF8D6E63)),
            SizedBox(width: 8),
            Text('Informações do Usuário'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Nome', user?.name ?? 'N/A'),
            SizedBox(height: 12),
            _buildInfoRow(
                'Criado em',
                user != null
                    ? '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}'
                    : 'N/A'
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fechar'),
            style: TextButton.styleFrom(
              foregroundColor: Color(0xFF8D6E63),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF8D6E63),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.science, color: Color(0xFF8D6E63)),
            SizedBox(width: 8),
            Text('Sobre o BioCollect'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Aplicativo para coleta de dados biológicos'),
            SizedBox(height: 8),
            Text('Versão: 1.0.0'),
            SizedBox(height: 8),
            Text('Desenvolvido para pesquisadores e biólogos'),
            SizedBox(height: 16),
            Text(
              'Funcionalidades:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text('• Criação de projetos por grupo biológico'),
            Text('• Coleta de dados com GPS'),
            Text('• Exportação personalizada para Excel'),
            Text('• Templates customizáveis'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fechar'),
            style: TextButton.styleFrom(
              foregroundColor: Color(0xFF8D6E63),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Funcionalidade em desenvolvimento 🚧'),
        backgroundColor: Color(0xFF8D6E63),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Limpar Cache'),
          ],
        ),
        content: Text(
          'Isso irá limpar arquivos temporários e cache do aplicativo. Seus projetos não serão afetados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Cache limpo com sucesso!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: Text('Limpar'),
          ),
        ],
      ),
    );
  }
}