import 'dart:developer';

import 'package:date_format/date_format.dart' as date_format;
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:memo_book/task.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: '记事本'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<WtcTask> tasks = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _contentController = TextEditingController();
  final WtcTaskService wtcTaskService = WtcTaskService();
  int pageNum = 1;
  final int pageSize = 13;
  bool hasNextPage = true;
  TaskStatus? filterStatus = TaskStatus.wait;

  @override
  void initState() {
    super.initState();
    initData();
  }

  Future initData() async {
    flushData();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        if (hasNextPage) {
          pageNum++;
          flushData();
        }
      }
    });
  }

  Future resetData() async {
    tasks = [];
    hasNextPage = true;
    pageNum = 1;
    flushData();
  }

  flushData() async {
    List<WtcTask>? result =
        await wtcTaskService.listWtcTask(pageNum, pageSize, filterStatus == null ? null : filterStatus!.index);
    if (result != null) {
      if (result.length < pageSize) {
        hasNextPage = false;
      }
      setState(() {
        tasks.addAll(result);
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
    _contentController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          GestureDetector(
            onTap: () {
              setState(() {
                if (filterStatus == null) {
                  filterStatus = TaskStatus.wait;
                } else {
                  filterStatus = null;
                }
              });
              resetData();
            },
            child: Row(
              children: [
                filterStatus == null
                    ? const Icon(Icons.switch_left)
                    : const Icon(
                        Icons.switch_right,
                        color: Colors.red,
                      ),
                const SizedBox(
                  width: 10,
                ),
                filterStatus == null
                    ? const Text("全部")
                    : const Text(
                        "待办",
                        style: TextStyle(color: Colors.red),
                      ),
              ],
            ),
          ),
          const SizedBox(
            width: 10,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Align(
                // 此处为关键代码
                alignment: Alignment.topCenter,
                child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    controller: _scrollController,
                    shrinkWrap: true,
                    itemCount: tasks.length,
                    itemExtent: 50,
                    itemBuilder: (context, index) {
                      WtcTask task = tasks[index];
                      return Slidable(
                        key: ValueKey(task.id),
                        endActionPane: ActionPane(
                          extentRatio: 0.2,
                          motion: const ScrollMotion(),
                          children: [
                            InkWell(
                              onTap: () {
                                log("del");
                                wtcTaskService.delete(task.id!);
                                setState(() {
                                  tasks.removeAt(index);
                                });
                              },
                              child: Container(
                                width: 80,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.all(Radius.circular(20)),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.delete_forever,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        child: ContentRowWidget(
                          task: task,
                          service: wtcTaskService,
                        ),
                      );
                    }),
              ),
            ),
            Container(
              height: 80,
              margin: const EdgeInsets.only(left: 10, right: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                color: Colors.white54,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                      child: TextField(
                    controller: _contentController,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Color(0xFF666666)),
                      hintText: "新的任务",
                    ),
                  )),
                  const SizedBox(
                    width: 20,
                  ),
                  InkWell(
                    onTap: () {
                      String content = _contentController.text;
                      if (content.isEmpty) {
                        return;
                      }

                      int id = tasks.isEmpty ? 1 : tasks.first.id! + 1;
                      WtcTask task = WtcTask(
                          id: id, content: content, createdTime: DateTime.now(), status: TaskStatus.wait, seq: id);
                      wtcTaskService.insert(task);
                      setState(() {
                        tasks.insert(0, task);
                        _contentController.text = "";
                        FocusScope.of(context).requestFocus(FocusNode());
                        hrefTop();
                      });
                    },
                    child: const Icon(
                      Icons.add,
                      size: 50,
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }

  hrefTop() {
    Future.delayed(const Duration(seconds: 1), () {
      _scrollController.jumpTo(_scrollController.position.minScrollExtent);
    });
  }
}

class ContentRowWidget extends StatefulWidget {
  final WtcTask task;
  final WtcTaskService service;

  const ContentRowWidget({super.key, required this.task, required this.service});

  @override
  State<ContentRowWidget> createState() => ContentWidgetSate();
}

class ContentWidgetSate extends State<ContentRowWidget> {
  late WtcTask task;

  @override
  void initState() {
    super.initState();
    task = widget.task;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 10,
        ),
        GestureDetector(
          onTap: () {
            if (task.status == TaskStatus.wait) {
              widget.service.update(task);
              setState(() {
                task.status = TaskStatus.finish;
              });
            }
          },
          child: task.status == TaskStatus.wait
              ? const Icon(
                  Icons.circle_outlined,
                  color: Colors.red,
                )
              : const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                ),
        ),
        const SizedBox(
          width: 10,
        ),
        Expanded(child: Text(task.content ?? "")),
        const SizedBox(
          width: 10,
        ),
        Text(date_format.formatDate(task.createdTime!,
            [date_format.yyyy, '-', date_format.mm, '-', date_format.dd, ' ', date_format.HH, ':', date_format.nn])),
        const SizedBox(
          width: 10,
        ),
      ],
    );
  }
}
