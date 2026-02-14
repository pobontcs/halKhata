import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ActivityServices {

      static Future<void> log({required String title,
                                required String subTitle,
                                  required String type})
                      async {
                                try{
                                          final String uid= FirebaseAuth.instance.currentUser!.uid;

                                          await FirebaseFirestore.instance.collection('activities').add(
                                              {
                                                'uid':uid,
                                                'title':title,
                                                'subtitle':subTitle,
                                                'type':type,
                                                'timestamp':FieldValue.serverTimestamp(),
                                              });
                                }
                                catch(e){
                                  print("Failed to log activity: $e");
                                }
                      }

      }


