/**
 * Seed Script — Generates gym class documents in Firestore for upcoming weeks.
 *
 * Usage:
 *   1. Download your Firebase service account key:
 *      Firebase Console → Project Settings → Service accounts → Generate new private key
 *   2. Save it as scripts/serviceAccountKey.json
 *   3. Run: node scripts/seed-schedule.js
 *
 * Options:
 *   --weeks=N     Number of weeks to generate (default: 4)
 *   --clear       Delete existing future classes before seeding
 */

import { initializeApp, cert } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { readFileSync } from "fs";
import { dirname, join } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));

// --- Firebase init ---
const serviceAccount = JSON.parse(
  readFileSync(join(__dirname, "serviceAccountKey.json"), "utf-8")
);
initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

// ============================================================
// WEEKLY SCHEDULE TEMPLATE
// Edit this to change your recurring classes.
// day: 0 = Sunday, 1 = Monday, ... 6 = Saturday
// hour/minute: 24-hour format
// level: "beginner" | "intermediate" | "advanced"
// ============================================================
const weeklyTemplate = [
  // Monday
  { day: 1, hour: 6,  minute: 0,  name: "Morning HIIT",        instructor: "Coach Mike",    durationMinutes: 45, level: "intermediate", location: "Studio A", totalSpots: 20, description: "High intensity interval training to start your day" },
  { day: 1, hour: 9,  minute: 0,  name: "Yoga Flow",           instructor: "Sarah Chen",    durationMinutes: 60, level: "beginner",     location: "Studio B", totalSpots: 15, description: "Gentle yoga flow for all levels" },
  { day: 1, hour: 12, minute: 0,  name: "Lunch Burn",          instructor: "Coach Mike",    durationMinutes: 30, level: "intermediate", location: "Studio A", totalSpots: 25, description: "Quick midday cardio blast" },
  { day: 1, hour: 17, minute: 30, name: "Strength Training",   instructor: "Jake Torres",   durationMinutes: 60, level: "advanced",     location: "Weight Room", totalSpots: 12, description: "Barbell and dumbbell compound lifts" },
  { day: 1, hour: 19, minute: 0,  name: "Boxing Fundamentals", instructor: "Coach Mike",    durationMinutes: 45, level: "beginner",     location: "Studio A", totalSpots: 16, description: "Learn boxing basics and get a great workout" },

  // Tuesday
  { day: 2, hour: 6,  minute: 0,  name: "Spin Class",          instructor: "Lisa Park",     durationMinutes: 45, level: "intermediate", location: "Spin Room", totalSpots: 20, description: "Indoor cycling with intervals" },
  { day: 2, hour: 9,  minute: 30, name: "Pilates Core",        instructor: "Sarah Chen",    durationMinutes: 50, level: "beginner",     location: "Studio B", totalSpots: 15, description: "Core-focused pilates session" },
  { day: 2, hour: 17, minute: 0,  name: "CrossFit WOD",        instructor: "Jake Torres",   durationMinutes: 60, level: "advanced",     location: "Weight Room", totalSpots: 14, description: "Workout of the day — varied functional movements" },
  { day: 2, hour: 18, minute: 30, name: "Stretch & Recover",   instructor: "Sarah Chen",    durationMinutes: 30, level: "beginner",     location: "Studio B", totalSpots: 20, description: "Active recovery and deep stretching" },

  // Wednesday
  { day: 3, hour: 6,  minute: 0,  name: "Morning HIIT",        instructor: "Coach Mike",    durationMinutes: 45, level: "intermediate", location: "Studio A", totalSpots: 20, description: "High intensity interval training to start your day" },
  { day: 3, hour: 10, minute: 0,  name: "Barre Sculpt",        instructor: "Lisa Park",     durationMinutes: 50, level: "intermediate", location: "Studio B", totalSpots: 15, description: "Ballet-inspired toning and sculpting" },
  { day: 3, hour: 12, minute: 0,  name: "Lunch Burn",          instructor: "Coach Mike",    durationMinutes: 30, level: "intermediate", location: "Studio A", totalSpots: 25, description: "Quick midday cardio blast" },
  { day: 3, hour: 17, minute: 30, name: "Strength Training",   instructor: "Jake Torres",   durationMinutes: 60, level: "advanced",     location: "Weight Room", totalSpots: 12, description: "Barbell and dumbbell compound lifts" },

  // Thursday
  { day: 4, hour: 6,  minute: 0,  name: "Spin Class",          instructor: "Lisa Park",     durationMinutes: 45, level: "intermediate", location: "Spin Room", totalSpots: 20, description: "Indoor cycling with intervals" },
  { day: 4, hour: 9,  minute: 0,  name: "Yoga Flow",           instructor: "Sarah Chen",    durationMinutes: 60, level: "beginner",     location: "Studio B", totalSpots: 15, description: "Gentle yoga flow for all levels" },
  { day: 4, hour: 17, minute: 0,  name: "CrossFit WOD",        instructor: "Jake Torres",   durationMinutes: 60, level: "advanced",     location: "Weight Room", totalSpots: 14, description: "Workout of the day — varied functional movements" },
  { day: 4, hour: 19, minute: 0,  name: "Boxing Fundamentals", instructor: "Coach Mike",    durationMinutes: 45, level: "beginner",     location: "Studio A", totalSpots: 16, description: "Learn boxing basics and get a great workout" },

  // Friday
  { day: 5, hour: 6,  minute: 0,  name: "Morning HIIT",        instructor: "Coach Mike",    durationMinutes: 45, level: "intermediate", location: "Studio A", totalSpots: 20, description: "High intensity interval training to start your day" },
  { day: 5, hour: 9,  minute: 30, name: "Pilates Core",        instructor: "Sarah Chen",    durationMinutes: 50, level: "beginner",     location: "Studio B", totalSpots: 15, description: "Core-focused pilates session" },
  { day: 5, hour: 12, minute: 0,  name: "Lunch Burn",          instructor: "Coach Mike",    durationMinutes: 30, level: "intermediate", location: "Studio A", totalSpots: 25, description: "Quick midday cardio blast" },
  { day: 5, hour: 17, minute: 0,  name: "Open Gym",            instructor: "Jake Torres",   durationMinutes: 90, level: "beginner",     location: "Weight Room", totalSpots: 30, description: "Open floor with coaching available" },

  // Saturday
  { day: 6, hour: 8,  minute: 0,  name: "Weekend Warrior HIIT", instructor: "Coach Mike",   durationMinutes: 60, level: "advanced",     location: "Studio A", totalSpots: 20, description: "Extended HIIT session to crush the weekend" },
  { day: 6, hour: 10, minute: 0,  name: "Yoga Flow",            instructor: "Sarah Chen",   durationMinutes: 75, level: "beginner",     location: "Studio B", totalSpots: 18, description: "Extended weekend yoga flow" },
  { day: 6, hour: 12, minute: 0,  name: "Kickboxing",           instructor: "Coach Mike",   durationMinutes: 45, level: "intermediate", location: "Studio A", totalSpots: 16, description: "Cardio kickboxing combinations" },

  // Sunday
  { day: 0, hour: 9,  minute: 0,  name: "Stretch & Recover",   instructor: "Sarah Chen",    durationMinutes: 45, level: "beginner",     location: "Studio B", totalSpots: 20, description: "Active recovery and deep stretching" },
  { day: 0, hour: 10, minute: 30, name: "Open Gym",            instructor: "Jake Torres",   durationMinutes: 120, level: "beginner",    location: "Weight Room", totalSpots: 30, description: "Open floor with coaching available" },
];

// ============================================================
// Script logic — no need to edit below
// ============================================================

const args = process.argv.slice(2);
const weeksToGenerate = parseInt(args.find(a => a.startsWith("--weeks="))?.split("=")[1] || "4");
const shouldClear = args.includes("--clear");

function getNextDateForDay(dayOfWeek, startFrom) {
  const date = new Date(startFrom);
  const diff = (dayOfWeek - date.getDay() + 7) % 7;
  date.setDate(date.getDate() + diff);
  return date;
}

async function clearFutureClasses() {
  const now = Timestamp.now();
  const snapshot = await db.collection("classes")
    .where("dateTime", ">=", now)
    .get();

  if (snapshot.empty) {
    console.log("No future classes to clear.");
    return;
  }

  const batch = db.batch();
  snapshot.docs.forEach(doc => batch.delete(doc.ref));
  await batch.commit();
  console.log(`Deleted ${snapshot.size} future class documents.`);
}

async function seedClasses() {
  console.log(`Generating classes for ${weeksToGenerate} week(s)...`);

  const today = new Date();
  today.setHours(0, 0, 0, 0);

  let totalCreated = 0;
  const batch = db.batch();

  for (let week = 0; week < weeksToGenerate; week++) {
    const weekStart = new Date(today);
    weekStart.setDate(weekStart.getDate() + week * 7);

    for (const template of weeklyTemplate) {
      const classDate = getNextDateForDay(template.day, weekStart);
      classDate.setHours(template.hour, template.minute, 0, 0);

      // Skip classes in the past
      if (classDate < new Date()) continue;

      const docRef = db.collection("classes").doc();
      batch.set(docRef, {
        name: template.name,
        instructor: template.instructor,
        dateTime: Timestamp.fromDate(classDate),
        durationMinutes: template.durationMinutes,
        level: template.level,
        description: template.description,
        location: template.location,
        totalSpots: template.totalSpots,
        bookedCount: 0,
      });
      totalCreated++;
    }
  }

  await batch.commit();
  console.log(`Created ${totalCreated} class documents.`);
}

async function main() {
  try {
    if (shouldClear) {
      await clearFutureClasses();
    }
    await seedClasses();
    console.log("Done!");
  } catch (err) {
    console.error("Error:", err.message);
    process.exit(1);
  }
}

main();
