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
 *   --verify      Read back classes from Firestore after seeding to confirm
 *   --dry-run     Show what would be created without writing to Firestore
 */

import { initializeApp, cert } from "firebase-admin/app";
import { getFirestore, Timestamp, FieldValue } from "firebase-admin/firestore";
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

const VALID_LEVELS = ["beginner", "intermediate", "advanced"];
const DAY_NAMES = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

const args = process.argv.slice(2);
const weeksToGenerate = parseInt(args.find(a => a.startsWith("--weeks="))?.split("=")[1] || "4");
const shouldClear = args.includes("--clear");
const shouldVerify = args.includes("--verify");
const isDryRun = args.includes("--dry-run");

function validateTemplate() {
  const errors = [];
  for (let i = 0; i < weeklyTemplate.length; i++) {
    const t = weeklyTemplate[i];
    const label = `Template[${i}] "${t.name || "unnamed"}"`;
    if (typeof t.name !== "string" || !t.name) errors.push(`${label}: missing name`);
    if (typeof t.instructor !== "string" || !t.instructor) errors.push(`${label}: missing instructor`);
    if (typeof t.day !== "number" || t.day < 0 || t.day > 6) errors.push(`${label}: day must be 0-6`);
    if (typeof t.hour !== "number" || t.hour < 0 || t.hour > 23) errors.push(`${label}: hour must be 0-23`);
    if (typeof t.minute !== "number" || t.minute < 0 || t.minute > 59) errors.push(`${label}: minute must be 0-59`);
    if (typeof t.durationMinutes !== "number" || t.durationMinutes <= 0) errors.push(`${label}: durationMinutes must be > 0`);
    if (!VALID_LEVELS.includes(t.level)) errors.push(`${label}: level must be one of ${VALID_LEVELS.join(", ")}`);
    if (typeof t.location !== "string" || !t.location) errors.push(`${label}: missing location`);
    if (typeof t.description !== "string") errors.push(`${label}: missing description`);
    if (typeof t.totalSpots !== "number" || t.totalSpots <= 0) errors.push(`${label}: totalSpots must be > 0`);
  }
  return errors;
}

function getNextDateForDay(dayOfWeek, startFrom) {
  const date = new Date(startFrom);
  const diff = (dayOfWeek - date.getDay() + 7) % 7;
  date.setDate(date.getDate() + diff);
  return date;
}

function formatDate(d) {
  return d.toLocaleString("en-US", {
    weekday: "short", month: "short", day: "numeric",
    hour: "numeric", minute: "2-digit", hour12: true,
  });
}

async function clearFutureClasses() {
  const now = Timestamp.now();
  const snapshot = await db.collection("classes")
    .where("dateTime", ">=", now)
    .get();

  if (snapshot.empty) {
    console.log("  No future classes to clear.");
    return;
  }

  // Firestore batches are limited to 500 operations
  const chunks = [];
  for (let i = 0; i < snapshot.docs.length; i += 500) {
    chunks.push(snapshot.docs.slice(i, i + 500));
  }
  for (const chunk of chunks) {
    const batch = db.batch();
    chunk.forEach(doc => batch.delete(doc.ref));
    await batch.commit();
  }
  console.log(`  Deleted ${snapshot.size} future class documents.`);
}

async function seedClasses() {
  console.log(`\nGenerating classes for ${weeksToGenerate} week(s)...\n`);

  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const docsToCreate = [];

  for (let week = 0; week < weeksToGenerate; week++) {
    const weekStart = new Date(today);
    weekStart.setDate(weekStart.getDate() + week * 7);

    for (const template of weeklyTemplate) {
      const classDate = getNextDateForDay(template.day, weekStart);
      classDate.setHours(template.hour, template.minute, 0, 0);

      // Skip classes in the past
      if (classDate < new Date()) continue;

      docsToCreate.push({
        name: template.name,
        instructor: template.instructor,
        dateTime: Timestamp.fromDate(classDate),
        durationMinutes: Math.round(template.durationMinutes),  // ensure integer
        level: template.level,
        description: template.description,
        location: template.location,
        totalSpots: Math.round(template.totalSpots),  // ensure integer
        bookedCount: 0,
        _preview: `  ${DAY_NAMES[classDate.getDay()]} ${formatDate(classDate)} — ${template.name} (${template.instructor})`,
      });
    }
  }

  // Print preview
  console.log(`Classes to create (${docsToCreate.length}):`);
  let lastDay = "";
  for (const d of docsToCreate) {
    const dayKey = d.dateTime.toDate().toDateString();
    if (dayKey !== lastDay) {
      lastDay = dayKey;
      console.log("");
    }
    console.log(d._preview);
  }
  console.log("");

  if (isDryRun) {
    console.log("Dry run — nothing written to Firestore.");
    return 0;
  }

  // Write in batches of 500
  const chunks = [];
  for (let i = 0; i < docsToCreate.length; i += 500) {
    chunks.push(docsToCreate.slice(i, i + 500));
  }

  for (const chunk of chunks) {
    const batch = db.batch();
    for (const doc of chunk) {
      const { _preview, ...data } = doc;
      batch.set(db.collection("classes").doc(), data);
    }
    await batch.commit();
  }

  console.log(`Created ${docsToCreate.length} class documents in Firestore.`);
  return docsToCreate.length;
}

async function verifyClasses() {
  console.log("\nVerifying — reading classes back from Firestore...\n");

  const now = Timestamp.now();
  const snapshot = await db.collection("classes")
    .where("dateTime", ">=", now)
    .orderBy("dateTime")
    .limit(50)
    .get();

  if (snapshot.empty) {
    console.log("  WARNING: No future classes found in Firestore!");
    console.log("  Possible causes:");
    console.log("    - The seed script wrote to a different Firebase project");
    console.log("    - Firestore rules are blocking reads");
    console.log("    - The seed failed silently");
    return;
  }

  console.log(`  Found ${snapshot.size} future classes (showing up to 50):\n`);
  for (const doc of snapshot.docs) {
    const d = doc.data();
    const dt = d.dateTime.toDate();
    console.log(`  [${doc.id}]`);
    console.log(`    name: ${d.name}  |  instructor: ${d.instructor}`);
    console.log(`    dateTime: ${formatDate(dt)}  |  level: ${d.level}`);
    console.log(`    durationMinutes: ${d.durationMinutes} (${typeof d.durationMinutes})  |  totalSpots: ${d.totalSpots} (${typeof d.totalSpots})  |  bookedCount: ${d.bookedCount} (${typeof d.bookedCount})`);
    console.log(`    location: ${d.location}  |  description: ${d.description ? d.description.substring(0, 40) + "..." : "MISSING"}`);
    console.log("");
  }

  // Check for fields the app needs
  const sample = snapshot.docs[0].data();
  const requiredFields = ["name", "instructor", "dateTime", "durationMinutes", "level", "description", "location", "totalSpots", "bookedCount"];
  const missing = requiredFields.filter(f => !(f in sample));
  if (missing.length > 0) {
    console.log(`  WARNING: Documents are missing required fields: ${missing.join(", ")}`);
  } else {
    console.log("  All required fields present.");
  }

  if (!VALID_LEVELS.includes(sample.level)) {
    console.log(`  WARNING: level="${sample.level}" is not one of ${VALID_LEVELS.join(", ")}`);
  }
}

async function main() {
  console.log("=== ForceSub Schedule Seeder ===\n");

  // Validate template first
  const errors = validateTemplate();
  if (errors.length > 0) {
    console.error("Template validation failed:");
    errors.forEach(e => console.error(`  - ${e}`));
    process.exit(1);
  }
  console.log(`Template OK (${weeklyTemplate.length} classes/week)`);

  try {
    if (shouldClear) {
      console.log("\nClearing existing future classes...");
      await clearFutureClasses();
    }

    await seedClasses();

    if (shouldVerify || isDryRun === false) {
      await verifyClasses();
    }

    console.log("\nDone!");
  } catch (err) {
    console.error("\nError:", err.message);
    console.error(err.stack);
    process.exit(1);
  }
}

main();
