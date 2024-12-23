package main

import (
	"archive/internal"
	"log"
)

func main() {
	db, err := internal.InitDB()
	if err != nil {
		log.Fatalf("Failed to connect to the database: %v", err)
	}
	defer db.Close()

	log.Println("Seeding the database...")
	internal.SeedDB(db)
	log.Println("Database seeding complete.")
}
