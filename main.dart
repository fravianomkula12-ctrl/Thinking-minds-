import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

const navy = Color(0xFF062B4F);
const cyan = Color(0xFF00B9D6);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ThinkingMindsApp());
}

class ThinkingMindsApp extends StatefulWidget {
  const ThinkingMindsApp({super.key});
  @override
  State<ThinkingMindsApp> createState() => _ThinkingMindsAppState();
}

class _ThinkingMindsAppState extends State<ThinkingMindsApp> {
  bool sw = false;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Thinking Minds',
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: navy),
      scaffoldBackgroundColor: const Color(0xFFF5F8FC),
      appBarTheme: const AppBarTheme(backgroundColor: navy, foregroundColor: Colors.white),
    ),
    home: AuthGate(swahili: sw, onLanguage: (v) => setState(() => sw = v)),
  );
}

String t(bool sw, String en, String swText) => sw ? swText : en;

class AuthGate extends StatelessWidget {
  final bool sw;
  final ValueChanged<bool> onLanguage;
  const AuthGate({super.key, required this.sw, required this.onLanguage});
  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: FirebaseAuth.instance.authStateChanges(),
    builder: (context, auth) {
      if (auth.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (auth.data == null) return AuthScreen(swahili: sw, onLanguage: onLanguage);
      return MemberGate(user: auth.data!, sw: sw, onLanguage: onLanguage);
    },
  );
}

class AuthScreen extends StatefulWidget {
  final bool swahili;
  final ValueChanged<bool> onLanguage;
  const AuthScreen({super.key, required this.swahili, required this.onLanguage});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  final name = TextEditingController();
  bool register = false, busy = false;
  String? error;

  Future<void> submit() async {
    setState(() { busy = true; error = null; });
    try {
      if (register) {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.text.trim(), password: password.text,
        );
        await cred.user!.updateDisplayName(name.text.trim());
        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
          'uid': cred.user!.uid,
          'name': name.text.trim(),
          'email': email.text.trim(),
          'field': '',
          'bio': '',
          'role': 'member',
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.text.trim(), password: password.text,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => error = e.message ?? e.code);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() { email.dispose(); password.dispose(); name.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final sw = widget.swahili;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(
          colors: [navy, Color(0xFF087C9A)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: SafeArea(child: Center(child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440), child: Column(children: [
            Align(alignment: Alignment.centerRight, child: DropdownButton<bool>(
              value: sw, dropdownColor: navy, style: const TextStyle(color: Colors.white),
              items: const [DropdownMenuItem(value: false, child: Text('English')), DropdownMenuItem(value: true, child: Text('Kiswahili'))],
              onChanged: (v) { if (v != null) widget.onLanguage(v); },
            )),
            const Icon(Icons.psychology_alt_rounded, color: Colors.white, size: 82),
            const SizedBox(height: 10),
            const Text('THINKING MINDS', style: TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            Text(t(sw, 'Think Beyond Limits, Innovate for Humanity.', 'Fikiri Zaidi, Buni Suluhisho, Badili Dunia.'),
              textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 28),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
                Text(register ? t(sw,'Create an account','Fungua akaunti') : t(sw,'Welcome back','Karibu tena'),
                  style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: navy)),
                const SizedBox(height: 16),
                if (register) TextField(controller: name, decoration: InputDecoration(labelText: t(sw,'Full name','Jina kamili'), prefixIcon: const Icon(Icons.person_outline))),
                if (register) const SizedBox(height: 10),
                TextField(controller: email, keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: 'Email', prefixIcon: const Icon(Icons.email_outlined))),
                const SizedBox(height: 10),
                TextField(controller: password, obscureText: true,
                  decoration: InputDecoration(labelText: t(sw,'Password','Nenosiri'), prefixIcon: const Icon(Icons.lock_outline))),
                if (error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(error!, style: const TextStyle(color: Colors.red))),
                const SizedBox(height: 18),
                SizedBox(width: double.infinity, height: 48, child: FilledButton(
                  onPressed: busy ? null : submit,
                  child: busy ? const CircularProgressIndicator() : Text(register ? t(sw,'Apply for membership','Omba uanachama') : t(sw,'Login','Ingia')),
                )),
                TextButton(onPressed: () => setState(() { register = !register; error = null; }),
                  child: Text(register ? t(sw,'Already have an account? Login','Una akaunti? Ingia') : t(sw,'New here? Apply to join','Mgeni? Omba kujiunga'))),
              ])),
            ),
            const SizedBox(height: 12),
            const Text('MEMBERSHIP APPLICATIONS REQUIRE ADMIN APPROVAL', textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: .8)),
          ])),
        ))),
      ),
    );
  }
}

class MemberGate extends StatelessWidget {
  final User user;
  final bool sw;
  final ValueChanged<bool> onLanguage;
  const MemberGate({super.key, required this.user, required this.sw, required this.onLanguage});
  @override
  Widget build(BuildContext context) => StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
    stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
    builder: (context, snap) {
      if (snap.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));
      if (!snap.hasData || !snap.data!.exists) return StatusScreen(sw: sw, message: t(sw,'Your member profile is being prepared. Contact an administrator.','Wasifu wako unatayarishwa. Wasiliana na msimamizi.'));
      final data = snap.data!.data()!;
      if (data['status'] != 'approved') return PendingScreen(sw: sw);
      return AppShell(user: user, data: data, sw: sw, onLanguage: onLanguage);
    },
  );
}

class PendingScreen extends StatelessWidget {
  final bool sw;
  const PendingScreen({super.key, required this.sw});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.hourglass_top_rounded, size: 72, color: cyan),
      const SizedBox(height: 18),
      Text(t(sw,'Application under review','Ombi lako linapitiwa'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: navy)),
      const SizedBox(height: 10),
      Text(t(sw,'Thank you for applying to Thinking Minds. You can use the community after an administrator approves your membership.',
        'Asante kwa kuomba kujiunga na Thinking Minds. Utaweza kutumia jumuiya baada ya msimamizi kuidhinisha uanachama wako.'), textAlign: TextAlign.center),
      const SizedBox(height: 18),
      OutlinedButton(onPressed: () => FirebaseAuth.instance.signOut(), child: Text(t(sw,'Sign out','Toka'))),
    ]))),
  );
}

class StatusScreen extends StatelessWidget {
  final bool sw; final String message;
  const StatusScreen({super.key, required this.sw, required this.message});
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
    Text(message, textAlign: TextAlign.center),
    const SizedBox(height: 14),
    OutlinedButton(onPressed: () => FirebaseAuth.instance.signOut(), child: Text(t(sw,'Sign out','Toka'))),
  ]))));
}

class AppShell extends StatefulWidget {
  final User user; final Map<String,dynamic> data; final bool sw; final ValueChanged<bool> onLanguage;
  const AppShell({super.key, required this.user, required this.data, required this.sw, required this.onLanguage});
  @override
  State<AppShell> createState() => _AppShellState();
}
class _AppShellState extends State<AppShell> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    final sw = widget.sw;
    final isAdmin = widget.data['role'] == 'admin';
    final pages = [
      HomeTab(sw: sw, name: widget.data['name'] ?? ''),
      ChatTab(sw: sw, user: widget.user, name: widget.data['name'] ?? ''),
      IdeasTab(sw: sw, user: widget.user, name: widget.data['name'] ?? ''),
      isAdmin ? AdminTab(sw: sw) : ResearchTab(sw: sw),
      ProfileTab(sw: sw, data: widget.data, onLanguage: widget.onLanguage),
    ];
    final labels = [t(sw,'Home','Mwanzo'),t(sw,'Chat','Soga'),t(sw,'Ideas','Mawazo'),isAdmin?t(sw,'Admin','Msimamizi'):t(sw,'Research','Utafiti'),t(sw,'Profile','Wasifu')];
    final icons = [Icons.home,Icons.forum,Icons.lightbulb, isAdmin?Icons.admin_panel_settings:Icons.science,Icons.person];
    return Scaffold(
      appBar: AppBar(title: const Text('THINKING MINDS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: .7)),
        actions: [IconButton(onPressed: () => FirebaseAuth.instance.signOut(), icon: const Icon(Icons.logout))]),
      body: IndexedStack(index: tab, children: pages),
      bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (v)=>setState(()=>tab=v),
        destinations: List.generate(5,(i)=>NavigationDestination(icon:Icon(icons[i]),label:labels[i]))),
    );
  }
}

class HomeTab extends StatelessWidget {
  final bool sw; final String name;
  const HomeTab({super.key,required this.sw,required this.name});
  @override
  Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(18),children:[
    Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(borderRadius:BorderRadius.circular(20),gradient:const LinearGradient(colors:[navy,Color(0xFF087C9A)])),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('${t(sw,'Welcome','Karibu')}, $name!',style:const TextStyle(color:Colors.white,fontSize:22,fontWeight:FontWeight.bold)),
        const SizedBox(height:8),
        Text(t(sw,'Think, research, build and share solutions.','Fikiri, tafiti, tengeneza na shiriki suluhisho.'),style:const TextStyle(color:Colors.white70)),
        const SizedBox(height:14),const Text('THINK • DISCOVER • INNOVATE',style:TextStyle(color:cyan,fontWeight:FontWeight.w900)),
      ])),
    const SizedBox(height:18),
    Text(t(sw,'Community noticeboard','Matangazo ya jumuiya'),style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold,color:navy)),
    const SizedBox(height:8),
    StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('announcements').orderBy('createdAt',descending:true).limit(10).snapshots(),
      builder:(context,s){if(s.hasError)return const Text('Could not load announcements.');if(!s.hasData)return const LinearProgressIndicator();
        if(s.data!.docs.isEmpty)return Text(t(sw,'No announcements yet.','Hakuna matangazo kwa sasa.'));
        return Column(children: s.data!.docs.map((d) => _announcementCard(d.data())).toList());
      }),
  ]);
}


Widget _announcementCard(Map<String,dynamic> d)=>Card(
  elevation:0,color:Colors.white,child:ListTile(
    leading:const Icon(Icons.campaign,color:cyan),
    title:Text(d['title']??'Announcement',style:const TextStyle(fontWeight:FontWeight.bold)),
    subtitle:Text(d['body']??''),
  ));

class ChatTab extends StatefulWidget {
  final bool sw; final User user; final String name;
  const ChatTab({super.key,required this.sw,required this.user,required this.name});
  @override
  State<ChatTab> createState()=>_ChatTabState();
}
class _ChatTabState extends State<ChatTab>{
  final input=TextEditingController(); bool sending=false;
  Future<void> send()async{
    final value=input.text.trim();if(value.isEmpty)return;
    setState(()=>sending=true);
    try{
      await FirebaseFirestore.instance.collection('messages').add({
        'text':value,'uid':widget.user.uid,'name':widget.name,'createdAt':FieldValue.serverTimestamp(),
      });
      input.clear();
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
    if(mounted)setState(()=>sending=false);
  }
  @override
  void dispose(){input.dispose();super.dispose();}
  @override
  Widget build(BuildContext context)=>Column(children:[
    Padding(padding:const EdgeInsets.all(12),child:Text(t(widget.sw,'Thinking Minds community chat','Soga za jumuiya ya Thinking Minds'),style:const TextStyle(fontWeight:FontWeight.bold,color:navy))),
    Expanded(child:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
      stream:FirebaseFirestore.instance.collection('messages').orderBy('createdAt',descending:true).limit(100).snapshots(),
      builder:(context,s){if(s.hasError)return const Center(child:Text('Chat could not load.'));if(!s.hasData)return const Center(child:CircularProgressIndicator());
        if(s.data!.docs.isEmpty)return Center(child:Text(t(widget.sw,'Start the conversation.','Anzisha mazungumzo.')));
        return ListView(reverse:true,padding:const EdgeInsets.all(12),children:s.data!.docs.map((d){
          final m=d.data();final mine=m['uid']==widget.user.uid;
          return Align(alignment:mine?Alignment.centerRight:Alignment.centerLeft,child:Container(
            constraints:const BoxConstraints(maxWidth:310),margin:const EdgeInsets.symmetric(vertical:5),
            padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:mine?const Color(0xFFDDF7FC):Colors.white,borderRadius:BorderRadius.circular(14)),
            child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(m['name']??'Member',style:const TextStyle(fontWeight:FontWeight.bold,color:navy,fontSize:12)),
              const SizedBox(height:3),Text(m['text']??''),
            ])));
        }).toList());
      })),
    SafeArea(top:false,child:Padding(padding:const EdgeInsets.fromLTRB(12,6,12,10),child:Row(children:[
      Expanded(child:TextField(controller:input,minLines:1,maxLines:4,decoration:InputDecoration(hintText:t(widget.sw,'Write a message...','Andika ujumbe...'),filled:true,fillColor:Colors.white,border:OutlineInputBorder(borderRadius:BorderRadius.circular(24),borderSide:BorderSide.none)))),
      const SizedBox(width:8),IconButton.filled(onPressed:sending?null:send,icon:const Icon(Icons.send)),
    ]))),
  ]);
}

class IdeasTab extends StatefulWidget{
  final bool sw;final User user;final String name;
  const IdeasTab({super.key,required this.sw,required this.user,required this.name});
  @override State<IdeasTab> createState()=>_IdeasTabState();
}
class _IdeasTabState extends State<IdeasTab>{
  final title=TextEditingController(),description=TextEditingController();bool busy=false;
  Future<void> submit()async{
    if(title.text.trim().isEmpty||description.text.trim().isEmpty)return;
    setState(()=>busy=true);
    try{
      await FirebaseFirestore.instance.collection('ideas').add({
        'title':title.text.trim(),'description':description.text.trim(),'uid':widget.user.uid,
        'author':widget.name,'status':'submitted','createdAt':FieldValue.serverTimestamp(),
      });
      title.clear();description.clear();
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(t(widget.sw,'Idea submitted.','Wazo limewasilishwa.'))));
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
    if(mounted)setState(()=>busy=false);
  }
  @override void dispose(){title.dispose();description.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(16),children:[
    Text(t(widget.sw,'Innovation Lab','Maabara ya Ubunifu'),style:const TextStyle(fontSize:21,fontWeight:FontWeight.bold,color:navy)),
    const SizedBox(height:8),
    Text(t(widget.sw,'Submit an idea that could solve a real problem.','Wasilisha wazo linaloweza kutatua changamoto halisi.')),
    const SizedBox(height:12),
    TextField(controller:title,decoration:InputDecoration(labelText:t(widget.sw,'Idea title','Kichwa cha wazo'),filled:true,fillColor:Colors.white)),
    const SizedBox(height:10),
    TextField(controller:description,minLines:4,maxLines:7,decoration:InputDecoration(labelText:t(widget.sw,'Problem and proposed solution','Tatizo na suluhisho linalopendekezwa'),filled:true,fillColor:Colors.white)),
    const SizedBox(height:12),
    FilledButton.icon(onPressed:busy?null:submit,icon:const Icon(Icons.send),label:Text(t(widget.sw,'Submit idea','Wasilisha wazo'))),
    const SizedBox(height:20),
    Text(t(widget.sw,'Community ideas','Mawazo ya jumuiya'),style:const TextStyle(fontWeight:FontWeight.bold,fontSize:17,color:navy)),
    StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('ideas').orderBy('createdAt',descending:true).limit(30).snapshots(),
      builder:(context,s){if(!s.hasData)return const LinearProgressIndicator();return Column(children:s.data!.docs.map((d){final x=d.data();return Card(elevation:0,child:ListTile(title:Text(x['title']??''),subtitle:Text('${x['description']??''}\n— ${x['author']??'Member'}')));}).toList());}),
  ]);
}

class ResearchTab extends StatelessWidget{
  final bool sw;const ResearchTab({super.key,required this.sw});
  @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(18),children:[
    Text(t(sw,'Research Hub','Kituo cha Tafiti'),style:const TextStyle(fontSize:21,fontWeight:FontWeight.bold,color:navy)),
    const SizedBox(height:10),
    Card(elevation:0,child:ListTile(leading:const Icon(Icons.upload_file,color:cyan),title:Text(t(sw,'Research submissions','Mawasilisho ya tafiti')),subtitle:Text(t(sw,'The next release will add secure document upload and review workflows.','Toleo lijalo litaongeza upakiaji salama wa nyaraka na mfumo wa mapitio.')))),
    Card(elevation:0,child:ListTile(leading:const Icon(Icons.menu_book,color:cyan),title:Text(t(sw,'Scientific library','Maktaba ya kisayansi')),subtitle:Text(t(sw,'Curated papers, learning resources and references.','Makala, nyenzo za kujifunzia na marejeo.')))),
  ]);
}

class AdminTab extends StatelessWidget{
  final bool sw;const AdminTab({super.key,required this.sw});
  Future<void> approve(String uid)async=>FirebaseFirestore.instance.collection('users').doc(uid).update({'status':'approved'});
  Future<void> reject(String uid)async=>FirebaseFirestore.instance.collection('users').doc(uid).update({'status':'rejected'});
  @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(16),children:[
    Text(t(sw,'Admin dashboard','Dashibodi ya msimamizi'),style:const TextStyle(fontSize:21,fontWeight:FontWeight.bold,color:navy)),
    const SizedBox(height:8),
    Text(t(sw,'Review membership applications. Only approved administrators can see this page.','Pitia maombi ya uanachama. Wasimamizi walioidhinishwa pekee ndio wanaoweza kuona ukurasa huu.')),
    const SizedBox(height:12),
    StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('users').where('status',isEqualTo:'pending').snapshots(),
      builder:(context,s){if(s.hasError)return Text('Error: ${s.error}');if(!s.hasData)return const LinearProgressIndicator();
        if(s.data!.docs.isEmpty)return Text(t(sw,'No pending applications.','Hakuna maombi yanayosubiri.'));
        return Column(children:s.data!.docs.map((d){final x=d.data();return Card(child:ListTile(
          title:Text(x['name']??'Applicant'),subtitle:Text(x['email']??''),
          trailing:Wrap(spacing:2,children:[
            IconButton(tooltip:'Approve',onPressed:()=>approve(d.id),icon:const Icon(Icons.check_circle,color:Colors.green)),
            IconButton(tooltip:'Reject',onPressed:()=>reject(d.id),icon:const Icon(Icons.cancel,color:Colors.red)),
          ]),
        ));}).toList());
      }),
  ]);
}

class ProfileTab extends StatelessWidget{
  final bool sw;final Map<String,dynamic> data;final ValueChanged<bool> onLanguage;
  const ProfileTab({super.key,required this.sw,required this.data,required this.onLanguage});
  @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(18),children:[
    const Center(child:Icon(Icons.account_circle_rounded,size:80,color:cyan)),
    Center(child:Text(data['name']??'Member',style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold,color:navy))),
    Center(child:Text(data['email']??'')),
    const SizedBox(height:20),
    Card(elevation:0,child:ListTile(leading:const Icon(Icons.badge,color:cyan),title:Text(t(sw,'Membership role','Cheo cha uanachama')),subtitle:Text(data['role']??'member'))),
    Card(elevation:0,child:ListTile(leading:const Icon(Icons.language,color:cyan),title:Text(t(sw,'Language','Lugha')),trailing:DropdownButton<bool>(value:sw,items:const[
      DropdownMenuItem(value:false,child:Text('English')),DropdownMenuItem(value:true,child:Text('Kiswahili'))
    ],onChanged:(v){if(v!=null)onLanguage(v);}))),
    Card(elevation:0,child:ListTile(leading:const Icon(Icons.logout,color:cyan),title:Text(t(sw,'Sign out','Toka')),onTap:()=>FirebaseAuth.instance.signOut())),
  ]);
}
