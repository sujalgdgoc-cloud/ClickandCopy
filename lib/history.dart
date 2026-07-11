import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class History extends StatefulWidget {
  final String? generatedCode;

  const History({super.key, required this.generatedCode});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  late final Query history_query;
  final database = FirebaseDatabase.instance.ref('sessions');
  final TextEditingController searchController = TextEditingController();
  String? genCode;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    final code = widget.generatedCode ?? 'invalid';
    genCode = code;
    history_query = FirebaseDatabase.instance
        .ref('sessions')
        .child('history')
        .child(code)
        .orderByChild('sort_key');
    if (code != 'invalid') {
      clearHistory(code);
    }
  }

  Future<void> clearHistory(String roomCode) async {
    final int thirydaysinMilliseconds = 30 * 24 * 60 * 60 * 1000;
    final int cutoff =
        DateTime.now().millisecondsSinceEpoch - thirydaysinMilliseconds;

    try {
      final historyData = database.child('history').child(roomCode);

      final DataSnapshot expiredData = await historyData
          .orderByChild('created_at')
          .endAt(cutoff)
          .get();
      Map<dynamic, dynamic> expiredItem =
          expiredData.value as Map<dynamic, dynamic>;
      for (var key in expiredItem.keys) {
        await historyData.child(key).remove();
      }
      print('clear');
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFf7f9fb),
        appBar: AppBar(
          title: const Text(
            'Click&Copy',
            style: TextStyle(
              color: Color(0xFF2563EB),
              fontWeight: FontWeight.bold,
              fontSize: 21,
            ),
          ),),
      body: Column(
        children: [
          Card(
            color: Colors.amber.shade50,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'All the History of clipboard will be deleted in 30 days',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              onChanged: (value) {
                setState(() {});
              },
              controller: searchController,
              cursorColor: Colors.blue,
              decoration: InputDecoration(
                hintText: "Search previous clipboard data",
                prefixIcon: Icon(Icons.search),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(21),
                  borderSide: BorderSide(color: Colors.grey, width: .5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(21),
                  borderSide: BorderSide(color: Colors.blue, width: .5),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Recent Data',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 21,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: FirebaseAnimatedList(
                query: history_query,
                itemBuilder: (context, snapshot, animation, index) {
                  if (snapshot.exists) {
                    final String searchQuery = searchController.text;
                    final String text = snapshot.child('text').value.toString();
                    final int sortKey =
                        snapshot.child('sort_key').value as int ?? 2;
                    final bool isPinned = (sortKey == 1);
                    if (searchQuery.isNotEmpty &&
                        !text.toLowerCase().contains(searchQuery)) {
                      return SizedBox();
                    }
                    return Card(
                      elevation: 1.5,
                      color: const Color(0xFFF8FAFC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(
                          color: Colors.grey.shade300,
                          width: 0.8,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Row(
                              children: const [
                                Icon(
                                  Icons.content_paste,
                                  color: Color(0xFF2563EB),
                                  size: 22,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Clipboard",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            /// Clipboard Text
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                snapshot.child('text').value.toString(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                            const SizedBox(height: 18),

                            Row(
                              children: [

                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Clipboard.setData(
                                        ClipboardData(text: text),
                                      );
                                    },
                                    icon: const Icon(Icons.copy, size: 18),
                                    label: const Text("Copy"),
                                    style: ElevatedButton.styleFrom(
                                      elevation: 0,
                                      minimumSize: const Size.fromHeight(48),
                                      backgroundColor: const Color(0xFF2563EB),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 10),

                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      int newSortKey = isPinned ? 2 : 1;

                                      await database
                                          .child('history')
                                          .child(genCode!)
                                          .child(snapshot.key!)
                                          .update({
                                        'sort_key': newSortKey,
                                      });
                                    },
                                    icon: Icon(
                                      isPinned
                                          ? Icons.push_pin
                                          : Icons.push_pin_outlined,
                                      size: 18,
                                    ),
                                    label: Text(
                                      isPinned ? "Unpin" : "Pin",
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(48),
                                      foregroundColor: const Color(0xFF2563EB),
                                      side: const BorderSide(
                                        color: Color(0xFF2563EB),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 10),

                                SizedBox(
                                  height: 48,
                                  width: 48,
                                  child: IconButton(
                                    onPressed: () async {
                                      await database
                                          .child('history')
                                          .child(genCode!)
                                          .child(snapshot.key!)
                                          .remove();
                                    },
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.red.shade50,
                                      side: BorderSide(
                                        color: Colors.red.shade200,
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return Center(child: Text('No History exist'));
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
