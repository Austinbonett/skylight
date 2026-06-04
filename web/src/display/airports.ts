// Bundled airport geometry, drawn at true geographic position so departures and
// arrivals visibly line up with the runways. Coordinates from FAA/AirNav (KLGB).

export interface Runway {
  leIdent: string;
  heIdent: string;
  le: [number, number]; // [lat, lon]
  he: [number, number];
  widthFt: number;
}

export interface Airport {
  icao: string;
  name: string;
  runways: Runway[];
}

export const LGB: Airport = {
  icao: "KLGB",
  name: "LGB",
  runways: [
    // Runway 12/30 — main commercial runway, 10,000 ft
    { leIdent: "12", heIdent: "30", le: [33.826203, -118.161535], he: [33.806867, -118.138144], widthFt: 200 },
    // Runway 08L/26R — 6,192 ft
    { leIdent: "8L", heIdent: "26R", le: [33.822760, -118.163524], he: [33.822699, -118.143137], widthFt: 150 },
    // Runway 08R/26L — 3,918 ft
    { leIdent: "8R", heIdent: "26L", le: [33.813897, -118.161303], he: [33.813906, -118.148403], widthFt: 100 },
  ],
};

/** Airports drawn on the map (KLGB Long Beach; easy to extend). */
export const AIRPORTS: Airport[] = [LGB];
