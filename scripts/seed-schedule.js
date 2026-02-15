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
  { day: 1, hour: 6,  minute: 0,  name: "Open Mat",            instructor: "Simon",           durationMinutes: 60,  level: "all levels",      location: "Main mat", totalSpots: 30, description: "" },
  { day: 1, hour: 16, minute: 30, name: "Baby Jitsu",          instructor: "Caz",           durationMinutes: 30,  level: "4-8 yrs old",     location: "Main mat", totalSpots: 15, description: "" },
  { day: 1, hour: 17, minute: 0,  name: "Teens BJJ",           instructor: "Caz",           durationMinutes: 60,  level: "9-15 yrs old",    location: "Main mat", totalSpots: 20, description: "" },
  { day: 1, hour: 18, minute: 0,  name: "MMA",                 instructor: "Jamie",           durationMinutes: 60,  level: "all levels",      location: "Main mat", totalSpots: 30, description: "" },
  { day: 1, hour: 19, minute: 0,  name: "Nogi",                instructor: "Daz",           durationMinutes: 90,  level: "all levels",      location: "Main mat", totalSpots: 30, description: "" },

  // Tuesday
  { day: 2, hour: 17, minute: 0,  name: "Teens Nogi",          instructor: "Caz",           durationMinutes: 60,  level: "9-15 yrs old",    location: "Main mat", totalSpots: 20, description: "" },
  { day: 2, hour: 18, minute: 0,  name: "MMA Striking",        instructor: "Jamie",           durationMinutes: 60,  level: "all levels",      location: "Main mat", totalSpots: 30, description: "" },
  { day: 2, hour: 19, minute: 0,  name: "BJJ Fundamentals",    instructor: "Chris",           durationMinutes: 90,  level: "all levels",      location: "Main mat", totalSpots: 30, description: "" },

  // Wednesday
  { day: 3, hour: 17, minute: 0,  name: "Teens BJJ",           instructor: "Jamie",           durationMinutes: 60,  level: "9-15 yrs old",    location: "Main mat", totalSpots: 20, description: "" },
  { day: 3, hour: 18, minute: 0,  name: "MMA",                 instructor: "Jamie",           durationMinutes: 60,  level: "all levels",      location: "Main mat", totalSpots: 30, description: "" },
  { day: 3, hour: 19, minute: 0,  name: "Advanced BJJ",        instructor: "Simon",           durationMinutes: 90,  level: "coloured belts",  location: "Main mat", totalSpots: 25, description: "" },

  // Thursday
  { day: 4, hour: 18, minute: 0,  name: "MMA Striking",        instructor: "Jamie",           durationMinutes: 60,  level: "all levels",      location: "Main mat", totalSpots: 30, description: "" },
  { day: 4, hour: 19, minute: 0,  name: "BJJ",                 instructor: "Chris",           durationMinutes: 90,  level: "all levels",      location: "Main mat", totalSpots: 30, description: "" },

  // Friday
  
  // Saturday
  { day: 6, hour: 10, minute: 0,  name: "BJJ Fundamentals",    instructor: "Simon",           durationMinutes: 60,  level: "all levels",      location: "Main mat", totalSpots: 30, description: "" },
  { day: 6, hour: 11, minute: 0,  name: "Open Mat",            instructor: "Simon",           durationMinutes: 90,  level: "all levels",      location: "Main mat", totalSpots: 30, description: "" },

  // Sunday
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
