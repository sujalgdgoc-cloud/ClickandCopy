import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:totp_generator/totp_generator.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  String text = "Nothing in clipboard";
  final database = FirebaseDatabase.instance.ref('sessions');
  int? expire_time;
  bool isFirstTime = true;

  final TextEditingController txtcontroller = TextEditingController();
  final otp = TOTPGenerator();
  String? generatedcode;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // TODO: implement didChangeAppLifecycleState
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached)
      return;
    final isBackground = state == AppLifecycleState.resumed;
    if (isBackground) {
      getClipBoardData();
      print('clipboard service started');
    }
  }

  Future<void> getClipBoardData() async {
    final ClipboardData? clipboardData = await Clipboard.getData(
      Clipboard.kTextPlain,
    );
    if (clipboardData != null || clipboardData?.text != null) {
      setState(() {
        text = clipboardData!.text!;
        txtcontroller.text = text;
        print(text);
      });
    }
  }

  final bool loading = false;
  bool codeavail = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFf7f9fb),
      drawer: SafeArea(
        child: Drawer(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Connected Devices',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Divider(),
              Expanded(
                child: generatedcode == null
                    ? Text('No device connected')
                    : FirebaseAnimatedList(
                        query: database
                            .child('paring_room')
                            .child(generatedcode!)
                            .child("devices"),
                        itemBuilder: (context, snapshot, animation, index) {
                          if (!snapshot.exists) {
                            return Text('No device Connected');
                          }
                          return Card(

                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    snapshot.child('device_name',).value.toString(),
                                    style: TextStyle(fontWeight: FontWeight.w300, fontSize: 18),
                                  ),
                                  CircleAvatar(
                                    backgroundColor: Colors.green,
                                    radius: 5,
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: const Text(
          'Click&Copy',
          style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 21),
        ),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),

              const Text(
                "Enter your message",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
              ),

              const SizedBox(height: 8),

              const Text(
                "The message will be securely shared with the paired device.",
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.all(8),
                child: Card(
                  elevation: 2,
                  color: Color(0xFFF8FAFC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(21),
                    side: BorderSide(
                      color: Colors.grey,
                      width: .5
                    )
                  ),
                  child: TextFormField(
                    cursorColor: Colors.blue,
                    maxLines: 5,
                    controller: txtcontroller,
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFF8FAFC))
                      ),
                      hintText: "Enter Your message",
                      prefixIcon: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            height: 5,
                          ),
                          Icon(Icons.sms_outlined),
                        ],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(21),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(21),
                        borderSide: const BorderSide(
                          color: Colors.blue,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    // generated code here :)
                    final int current_time =
                        DateTime.now().millisecondsSinceEpoch;
                    if (expire_time != null && current_time < expire_time!) {
                      //resuing kr kahe hai session ko ya agar session exist kr raha hai to
                      await database
                          .child('paring_room')
                          .child(generatedcode!)
                          .set({
                            "text": txtcontroller.text.toString(),
                            'created_at': current_time,
                            'expires_at': expire_time,
                          });
                      await database
                          .child('history')
                          .child(generatedcode!)
                          .push()
                          .set({
                            "text": txtcontroller.text.toString(),
                            "created_at": current_time,
                            "sort_key": 2,
                          });
                      txtcontroller.clear();
                    } else {
                      if (generatedcode != null) {
                        await database
                            .child('paring_room')
                            .child(generatedcode!)
                            .remove();
                      }

                      final code = otp.generateTOTP(
                        secret: 'MTIzNDU2Nzg5MDEyMzQ1Njc4OTA=',
                        encoding: 'base64',
                        digits: 8,
                        interval: 120,
                        algorithm: HashAlgorithm.sha256,
                      );

                      print(code);

                      await database
                          .child('paring_room')
                          .child(code)
                          .onDisconnect()
                          .remove();

                      final int newExpiry = DateTime.now()
                          .add(const Duration(seconds: 300))
                          .millisecondsSinceEpoch;

                      setState(() {
                        generatedcode = code;
                        codeavail = true;
                        isFirstTime = false;
                        expire_time = newExpiry;
                      });

                      await database.child('paring_room').child(code).set({
                        "text": txtcontroller.text.toString(),
                        'created_at': current_time,
                        'expires_at': newExpiry,
                      });

                      await database
                          .child('history')
                          .child(generatedcode!)
                          .push()
                          .set({
                            "text": txtcontroller.text.toString(),
                            "created_at": current_time,
                            "sort_key": 2,
                          });

                      txtcontroller.clear();
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
                      Text(
                        "Send",
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Card(
                color: Color(0xFFF8FAFC),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Colors.grey,
                    width: .5
                  )
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Share this 8-digit-pin with only trusted person",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),

                      const SizedBox(height: 20),

                      Card(
                        elevation: 2,
                        color: Color(0xFFf6f9fb),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.blue.shade200,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    codeavail ? generatedcode![0] : "*",
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.blue.shade200,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    codeavail ? generatedcode![1] : "*",
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.blue.shade200,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    codeavail ? generatedcode![2] : "*",
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.blue.shade200,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    codeavail ? generatedcode![3] : "*",
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.blue.shade200,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    codeavail ? generatedcode![4] : "*",
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.blue.shade200,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    codeavail ? generatedcode![5] : "*",
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.blue.shade200,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    codeavail ? generatedcode![6] : "*",
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.blue.shade200,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    codeavail ? generatedcode![7] : "*",
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Card(
                        color: Colors.amber.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'All the pairing codes are valid for 5 minutes only.',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
