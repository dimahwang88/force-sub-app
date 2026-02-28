import Foundation
import FirebaseFirestore

enum BookingError: LocalizedError {
    case classFull
    case invalidClass
    case invalidBooking
    case alreadyBooked
    case unknown

    var errorDescription: String? {
        switch self {
        case .classFull: return "This class is full."
        case .invalidClass: return "Class data is invalid."
        case .invalidBooking: return "Booking data is invalid."
        case .alreadyBooked: return "You have already booked this class."
        case .unknown: return "An unexpected error occurred."
        }
    }
}

final class BookingService {
    private let db = Firestore.firestore()
    private let bookingsCollection = "bookings"
    private let classesCollection = "classes"

    /// Book a class using a Firestore transaction to atomically check spots,
    /// increment bookedCount, and create the booking document.
    func bookClass(gymClass: GymClass, userId: String) async throws -> Booking {
        guard let classId = gymClass.id else {
            throw BookingError.invalidClass
        }

        let classRef = db.collection(classesCollection).document(classId)
        let bookingRef = db.collection(bookingsCollection).document()

        let bookingData: [String: Any] = [
            "userId": userId,
            "classId": classId,
            "className": gymClass.name,
            "instructor": gymClass.instructor,
            "classDateTime": Timestamp(date: gymClass.dateTime),
            "classDurationMinutes": gymClass.durationMinutes,
            "classLevel": gymClass.level.rawValue,
            "location": gymClass.location,
            "bookedAt": Timestamp(date: Date()),
            "status": BookingStatus.confirmed.rawValue
        ]

        _ = try await db.runTransaction { transaction, errorPointer in
            let classDoc: DocumentSnapshot
            do {
                classDoc = try transaction.getDocument(classRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }

            guard let currentBooked = classDoc.data()?["bookedCount"] as? Int,
                  let totalSpots = classDoc.data()?["totalSpots"] as? Int else {
                errorPointer?.pointee = BookingError.invalidClass as NSError
                return nil
            }

            guard currentBooked < totalSpots else {
                errorPointer?.pointee = BookingError.classFull as NSError
                return nil
            }

            transaction.updateData(["bookedCount": currentBooked + 1], forDocument: classRef)
            transaction.setData(bookingData, forDocument: bookingRef)

            return nil
        }

        let doc = try await bookingRef.getDocument()
        guard let booking = try? doc.data(as: Booking.self) else {
            throw BookingError.unknown
        }
        return booking
    }

    /// Cancel a booking: set status to cancelled and decrement bookedCount.
    func cancelBooking(_ booking: Booking) async throws {
        guard let bookingId = booking.id else {
            throw BookingError.invalidBooking
        }

        let bookingRef = db.collection(bookingsCollection).document(bookingId)
        let classRef = db.collection(classesCollection).document(booking.classId)

        _ = try await db.runTransaction { transaction, errorPointer in
            transaction.updateData(
                ["status": BookingStatus.cancelled.rawValue],
                forDocument: bookingRef
            )

            let classDoc: DocumentSnapshot
            do {
                classDoc = try transaction.getDocument(classRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }

            if let currentBooked = classDoc.data()?["bookedCount"] as? Int, currentBooked > 0 {
                transaction.updateData(["bookedCount": currentBooked - 1], forDocument: classRef)
            }

            return nil
        }
    }

    /// Fetch all confirmed bookings for a user, ordered by class date.
    func fetchBookings(userId: String) async throws -> [Booking] {
        let snapshot = try await db.collection(bookingsCollection)
            .whereField("userId", isEqualTo: userId)
            .getDocuments()

        return snapshot.documents
            .compactMap { try? $0.data(as: Booking.self) }
            .filter { $0.status == .confirmed }
            .sorted { $0.classDateTime < $1.classDateTime }
    }

    /// Check if user already has a confirmed booking for a specific class.
    func existingBooking(userId: String, classId: String) async throws -> Booking? {
        let snapshot = try await db.collection(bookingsCollection)
            .whereField("userId", isEqualTo: userId)
            .getDocuments()

        return snapshot.documents
            .compactMap { try? $0.data(as: Booking.self) }
            .first { $0.classId == classId && $0.status == .confirmed }
    }
}
