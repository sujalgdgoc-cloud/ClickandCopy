import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:websocket_example/history.dart';

class Receive extends StatefulWidget {
  const Receive({super.key});

  @override
  State<Receive> createState() => _ReceiveState();
}

class _ReceiveState extends State<Receive> {
  final TextEditingController controller = TextEditingController();
  final TextEditingController Copycontroller = TextEditingController();
  bool isLoading = false;
  String? text;
  String? generatedCode;
  bool isDataavail = false;
  final TextEditingController nameController = TextEditingController();

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
        ),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => History(generatedCode: generatedCode),
                ),
              );
            },
            icon: Icon(Icons.history, color: Color(0xFF2563EB)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),

              const Text(
                "Pair with a Device",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              const Text(
                "Enter the 8 digit pin to receive the clipboard data.",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),

              Card(
                elevation: 2,
                color: Color(0xFFF8FAFC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey, width: .5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextFormField(
                    controller: nameController,
                    cursorColor: Colors.blue,
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFF8FAFC)),
                      ),
                      prefixIcon: const Icon(
                        Icons.devices_outlined,
                        color: Color(0xFF2563EB),
                      ),
                      hintText: "Device Name",
                      label: Text(
                        "Device Name",
                        style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFF8FAFC),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Card(
                elevation: 2,
                color: Color(0xFFF8FAFC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey, width: .5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    controller: controller,
                    cursorColor: Colors.blue,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.pin_outlined, color: Color(0xFF2563EB)),
                      label: Text('Security Pin', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w300,),),
                      hintText: "********",
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFF8FAFC)),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFF8FAFC),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                height: 55,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: () async {
                          String? pairing_code = controller.text.trim();

                          if (pairing_code.isEmpty || pairing_code.length < 8) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Invalid code')),
                            );
                            return;
                          }
                          if (nameController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Enter a vaild device name'),
                              ),
                            );
                            return;
                          }

                          setState(() {
                            isLoading = true;
                          });

                          try {
                            final database = FirebaseDatabase.instance
                                .ref('sessions')
                                .child('paring_room')
                                .child(pairing_code);

                            final deviceRef = database.child("devices").push();

                            await deviceRef.set({
                              "device_name": nameController.text
                            });

                            deviceRef.onDisconnect().remove();
                            final DataSnapshot snapshot = await database.get();

                            if (snapshot.exists) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Connected Successfully'),
                                ),
                              );

                              print('connected to database');

                              final mapdata = Map<dynamic, dynamic>.from(
                                snapshot.value as Map,
                              );

                              int expiry_time = mapdata['expires_at'] ?? 0;
                              int current_time =
                                  DateTime.now().millisecondsSinceEpoch;

                              if (current_time > expiry_time) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('The session expired'),
                                  ),
                                );
                              } else {
                                setState(() {
                                  final String syncText =
                                      mapdata['text'] ?? 'Invalid';

                                  text = syncText;
                                  isDataavail = true;
                                  Copycontroller.text = text.toString();
                                  isLoading = true;
                                  generatedCode = pairing_code;
                                  controller.clear();
                                });
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'The session expired or pin is invalid',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            print(e);
                          } finally {
                            setState(() {
                              isLoading = false;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded, color: Colors.white,),
                            SizedBox(width: 5,),
                            const Text(
                              "Request",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),

              const SizedBox(height: 30),

              const Text(
                "Clipboard Data",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              const Text(
                "The received clipboard content will appear below.",
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 16),

              Card(
                color: Color(0xFFF8FAFC),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side:BorderSide(
                    color: Colors.grey,
                    width: .5
                  )
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextFormField(
                    controller: Copycontroller,
                    cursorColor: Colors.blue,
                    maxLines: 5,
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFF8FAFC))
                      ),
                      label: Column(
                        children: [
                          Center(child: Text('Latest ClipBoard Data', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w300),)),
                        ],
                      ),
                      hintText: "Clipboard Data...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(21),
                        borderSide: BorderSide(color: Color(0xFFF8FAFC))
                      ),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(21),
                          borderSide: BorderSide(color: Color(0xFFF8FAFC))
                      )
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                height: 55,
                child: FilledButton.icon(
                  onPressed: () async {
                    if (Copycontroller.text.isNotEmpty) {
                      await Clipboard.setData(
                        ClipboardData(text: Copycontroller.text),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text(
                    "Copy",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
