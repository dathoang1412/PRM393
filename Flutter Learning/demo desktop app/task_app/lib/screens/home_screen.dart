import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../widgets/task_item.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var provider = Provider.of<TaskProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text("Task Manager")),
      body: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(controller: controller),
              ),
              ElevatedButton(
                onPressed: () {
                  provider.addTask(controller.text);
                  controller.clear();
                },
                child: Text("Add"),
              )
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: provider.tasks.length,
              itemBuilder: (context, index) {
                var task = provider.tasks[index];
                return TaskItem(
                  task: task,
                  onToggle: () => provider.toggleTask(index),
                  onDelete: () => provider.removeTask(index),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}