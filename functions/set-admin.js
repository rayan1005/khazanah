// Run this script from the functions directory after setting GOOGLE_APPLICATION_CREDENTIALS
// Or use: firebase functions:shell and call setAdminByPhone({ phone: '56272677', secret: 'khazanah_admin_2026' })

const admin = require('firebase-admin');

// Initialize with project ID
admin.initializeApp({
  projectId: 'khazanah-49252',
});

const db = admin.firestore();

async function setAdmin() {
  const phones = ['+96656272677', '56272677', '0562726777'];
  
  for (const phone of phones) {
    console.log(`Trying phone: ${phone}`);
    const snapshot = await db.collection('users').where('phone', '==', phone).limit(1).get();
    
    if (!snapshot.empty) {
      const userDoc = snapshot.docs[0];
      console.log(`Found user: ${userDoc.id}`);
      console.log(`Current data:`, userDoc.data());
      
      await userDoc.ref.update({ role: 'admin' });
      console.log(`Updated user ${userDoc.id} to admin!`);
      return;
    }
  }
  
  console.log('User not found with any of the phone formats');
  
  // List all users to help debug
  console.log('\nAll users:');
  const allUsers = await db.collection('users').get();
  allUsers.docs.forEach(doc => {
    const data = doc.data();
    console.log(`- ${doc.id}: phone=${data.phone}, role=${data.role}`);
  });
}

setAdmin()
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
