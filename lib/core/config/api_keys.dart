// FIXME: TEMPORARY — hardcoded ExerciseDB key per user request on 2026-05-15.
//
// REMOVE BEFORE: any git push, any APK/IPA build distributed outside this device,
// any screen share / pair session. Rotate the key on rapidapi.com after removal.
//
// This file is gitignored (see project root .gitignore). It is the fallback
// used by `FitnessRepository.apiKey` when the in-app Settings dialog hasn't
// stored a key in Hive. Once you've pasted a key into Settings, the runtime
// uses that one and you can blank this constant safely.

const String kExerciseDbApiKey =
    '2cbd31d01bmsh5d571e24c394a17p1ecf19jsn780bab2daae2';

// FIXME: TEMPORARY — hardcoded NewsAPI key per user request on 2026-05-16.
// REMOVE BEFORE: any git push, APK/IPA build distributed outside this device,
// any screen share / pair session. Rotate at newsapi.org after removal.
// This file is gitignored — it will never be committed accidentally.
const String kNewsApiKey = 'd8ca5ad4052e41a7b71e5317841b1d39';
