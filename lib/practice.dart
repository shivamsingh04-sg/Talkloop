import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF6C63FF);
    const Color lightCardColor = Color(0xFFF8F8F8);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
          child: IntrinsicHeight(
            child: Column(
              children: [
                // Top Image + Avatar
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Image.asset(
                      'assets/images/bg2.png',
                      width: MediaQuery.of(context).size.width,
                      height: 250,
                      fit: BoxFit.fill,
                    ),
                    Positioned(
                      top: 200,
                      left: MediaQuery.of(context).size.width / 2 - 212,
                      child: const CircleAvatar(
                        radius: 85,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 82,
                          backgroundImage: AssetImage('assets/images/avatar.png'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 17),

                // Name & Role
                Container(
                  margin: EdgeInsets.only(left: 170,),
                  child: const Text(
                    'Vipin Sharma',
                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(left: 120,),
                  child: const Text(
                    'UI/UX Developer',
                    style: TextStyle(color: Colors.orange,fontSize: 20),
                  ),
                ),
                const SizedBox(height: 15),

                // Info Card
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    decoration: BoxDecoration(
                      color: lightCardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          children: [
                            const InfoRow(title: 'Reporting Manager', value: 'Vaibhav Korea', icon: Icons.person),
                            const Divider(),
                            const InfoRow(title: 'Employee Code', value: '56', icon: Icons.qr_code),
                            const Divider(),
                            const InfoRow(title: 'Email Id', value: 'vipinbsharma@nwaytech.com', icon: Icons.email_outlined),
                            const Divider(),
                            const InfoRow(title: 'Contact Details', value: '+91-9755089854', icon: Icons.phone_android),
                            const Divider(),
                            const InfoRow(title: 'Date of Birth', value: '28-02-1990', icon: Icons.cake),
                            const Divider(),
                            const InfoRow(title: 'Blood Group', value: 'A positive', icon: Icons.bloodtype_outlined),
                            const SizedBox(height: 2,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: Size(170, 20),
                                    backgroundColor: primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  child: const Text('SAVE',style: TextStyle(color: Colors.white,fontSize: 16,fontWeight: FontWeight.bold),),
                                ),
                                ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: Size(170, 20),
                                      backgroundColor: primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  child: const Text('CLOSE',style: TextStyle(color: Colors.white,fontSize: 16,fontWeight: FontWeight.bold),),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const InfoRow({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(fontSize: 12, color: Colors.black54),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      trailing: Icon(icon, color: Colors.deepPurple),
    );
  }
}
