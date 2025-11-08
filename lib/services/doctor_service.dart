import '../models/doctor.dart';

class DoctorService {
  static List<Doctor> getDoctors() {
    return [
      Doctor(
        name: 'Dr. Jean Dupont',
        specialty: 'Cardiologue',
        address: '123 Rue de la Santé, Paris',
        image: 'assets/images/doctor1.jpg',
      ),
      Doctor(
        name: 'Dr. Marie Martin',
        specialty: 'Dermatologue',
        address: '456 Avenue des Champs, Lyon',
        image: 'assets/images/doctor2.jpg',
      ),
      Doctor(
        name: 'Dr. Pierre Bernard',
        specialty: 'Neurologue',
        address: '789 Boulevard de la République, Marseille',
        image: 'assets/images/doctor3.jpg',
      ),
      Doctor(
        name: 'Dr. Sophie Petit',
        specialty: 'Pédiatre',
        address: '321 Rue Victor Hugo, Toulouse',
        image: 'assets/images/doctor4.jpg',
      ),
      Doctor(
        name: 'Dr. Laurent Durand',
        specialty: 'Ophtalmologue',
        address: '654 Rue de la Liberté, Nice',
        image: 'assets/images/doctor5.jpg',
      ),
      Doctor(
        name: 'Dr. Claire Leroy',
        specialty: 'Gynécologue',
        address: '987 Avenue Jean Jaurès, Bordeaux',
        image: 'assets/images/doctor6.jpg',
      ),
    ];
  }
}