import 'package:flutter/material.dart';
import 'package:chattranz/pages/create_group.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Groups'), centerTitle: true),
      body: const Center(
        child: Text('👥 Groups', style: TextStyle(fontSize: 20)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const CreateGroupPage()));
        },
        label: const Text('Create Group'),
        icon: const Icon(Icons.group_add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
