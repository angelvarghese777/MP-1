
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../chat/chat_page.dart';
import '../contacts/add_contact_page.dart';
import 'package:main_project_01/services/lan_discovery_service.dart';
import 'package:main_project_01/services/lan_tcp_service.dart';
import 'dart:async';
import 'package:main_project_01/services/pending_message_store.dart';

class HomePage extends StatefulWidget {
  final int userId;
  const HomePage({super.key,required this.userId,});

  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage>
{
List<Map<String, dynamic>> contacts = [];
  List<Map<String, dynamic>> filteredContacts = [];

  //lan
final LanDiscoveryService _lanDiscoveryService =
LanDiscoveryService();


final LanTcpService _lanTcpService = LanTcpService();

final PendingMessageStore _messageStore = PendingMessageStore();
StreamSubscription<Map<String, dynamic>>? _incomingSubscription;
//lan
Future<void> fetchContacts() async {
  debugPrint("CURRENT LOGGED-IN USER ID: ${widget.userId}");
  try {
    final response = await http.get(
      Uri.parse(
        "http://localhost:3000/contacts/${widget.userId}",
      ),
    );

    if (response.statusCode == 200) {

      final data = jsonDecode(response.body);

      debugPrint(data.toString());

      setState(() {
        contacts.clear();

        for (var contact in data["contacts"]) {
          contacts.add({
            "userId": contact["contact_user_id"],
            "name": contact["display_name"],
            "phone": contact["phone_no"],
          });
        }

        filteredContacts = List.from(contacts);
      });
    }
  } catch (e) {
    debugPrint(e.toString());
  }
}
  final TextEditingController searchController = TextEditingController();

  void searchContacts(String value) {
    setState(() {
      filteredContacts = contacts.where((contact) {
        return contact["name"]
            .toLowerCase()
            .contains(value.toLowerCase()) ||
            contact["phone"].contains(value);
      }).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    fetchContacts();

    _incomingSubscription =
        _lanTcpService.incomingMessages.listen((data) async {
          final senderId = int.tryParse(data['sender_id'].toString());
          final receiverId = int.tryParse(data['receiver_id'].toString());

          if (senderId == null ||
              receiverId != widget.userId ||
              data['type'] != 'chat') {
            return;
          }

          await _messageStore.saveConversationMessage(
            widget.userId,
            senderId,
            data,
          );

          debugPrint('Incoming LAN message saved locally.');
        });

    _startLanServices();
  }

  Future<void> _startLanServices() async {
    try {
      await _lanTcpService.start(
        onMessage: (message) {
          debugPrint('TCP MESSAGE RECEIVED: $message');
        },
      );

      await _lanDiscoveryService.start(userId: widget.userId);
    } catch (e) {
      debugPrint('Could not start LAN services: $e');
      // Cloud messaging should remain available.
    }
  }

  //lan

  @override
  void dispose() {
    _incomingSubscription?.cancel();
    searchController.dispose();
    _lanDiscoveryService.stop();
    _lanTcpService.stop();
    super.dispose();
  }

  //lan
  @override
  Widget build(BuildContext context) {
    return Scaffold(
       backgroundColor: const Color(0xFF15083A),
       body: 
       Column(
        children: [
          const SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Nyx",
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    ),
         Padding(
  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
  child: TextField(
    controller: searchController,
    onChanged: searchContacts,
    style: const TextStyle(
      color: Colors.white,
      fontSize: 15,
    ),
    cursorColor: const Color(0xFF8B5CF6),
    decoration: InputDecoration(
      filled: true,
      fillColor: Colors.white.withOpacity(0.08),
      hintText: "Search conversations...",
      hintStyle: const TextStyle(
        color: Colors.white54,
        fontSize: 15,
      ),
      prefixIcon: const Icon(
        Icons.search_rounded,
        color: Colors.white54,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFF8B5CF6),
          width: 1.5,
        ),
      ),
    ),
  ),
),

          Expanded(
            child: ListView.builder(
              itemCount: filteredContacts.length,
              itemBuilder: (context, index) {

                final contact =
                filteredContacts[index];
final String name = contact["name"].toString();
final String phone = contact["phone"].toString();

return ListTile(
  contentPadding: const EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 8,
  ),

  leading: Container(
    width: 52,
    height: 52,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        colors: [
          Color(0xFF8B5CF6),
          Color(0xFF6D28D9),
        ],
      ),
    ),
    child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : "?",
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),

  title: Text(
    name,
    style: const TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  ),

  subtitle: Padding(
    padding: const EdgeInsets.only(top: 5),
    child: Text(
      phone,
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 14,
      ),
    ),
  ),

  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(
                          userId: widget.userId,
                          receiverId: contact["userId"],
                          receiverName: contact["name"],
                          lanDiscoveryService: _lanDiscoveryService,
                          lanTcpService: _lanTcpService,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddContactPage(userId: widget.userId,
                lanDiscoveryService: _lanDiscoveryService,
                lanTcpService: _lanTcpService,),
            ),
          );
          if (result == true) {
            await fetchContacts();
          }
        },
        child: const Icon(Icons.add),
      ),
    );

  }
}

