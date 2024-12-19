package internal

import (
	"database/sql"
	"fmt"
	"github.com/labstack/echo/v4"
	"net/http"
	"strings"
)

func getReleasesCount(db *sql.DB, searchQuery string) (int, error) {
	query := "SELECT COUNT(*) FROM releases_fts"
	var args []interface{}
	if searchQuery != "" {
		query = "SELECT COUNT(*) FROM releases_fts WHERE to_tsvector(release_name || ' ' || artist_name) @@ plainto_tsquery($1)"
		args = append(args, searchQuery)
	}
	var count int
	err := db.QueryRow(query, args...).Scan(&count)
	if err != nil {
		return 0, err
	}
	return count, nil
}

func getPaginatedReleases(
	db *sql.DB,
	pageStr string,
	limitStr string,
	searchQuery string,
	logger echo.Logger,
	request *http.Request,
) ([]map[string]interface{},
	Pagination,
	error,
) {
	totalCount, err := getReleasesCount(db, searchQuery)
	if err != nil {
		logger.Printf("Failed to get releases count: %v", err)
	}

	pagination, err := getPagination(
		pageStr,
		limitStr,
		totalCount,
		request,
	)
	if err != nil {
		logger.Printf("Failed to get pagination: %v", err)
	}

	releases, err := getReleases(db, pagination.Limit, pagination.Offset, searchQuery, logger)

	return releases, pagination, err
}

func getReleases(db *sql.DB, limit int, offset int, searchQuery string, logger echo.Logger) ([]map[string]interface{}, error) {
	// Validate inputs
	if limit <= 0 {
		return nil, fmt.Errorf("invalid limit: %d", limit)
	}
	if offset < 0 {
		return nil, fmt.Errorf("invalid offset: %d", offset)
	}

	var query string
	var args []interface{}
	searchQuery = sanitizeQuery(searchQuery)

	if searchQuery != "" {
		query = `
		SELECT
			release_id,
			release_name,
			release_year,
			artist_name
		FROM releases_fts
		WHERE tsvector_column @@ plainto_tsquery($1)
		ORDER BY release_year ASC
		LIMIT $2
		OFFSET $3;
		`
		args = append(args, searchQuery, limit, offset)
	} else {
		query = `
		SELECT
			release_id,
			release_name,
			release_year,
			artist_name
		FROM releases_fts
		ORDER BY release_year ASC
		LIMIT $1
		OFFSET $2;
		`
		args = append(args, limit, offset)
	}

	logger.Printf("Executing query: %s with args: %v", query, args)

	rows, err := db.Query(query, args...)
	if err != nil {
		return nil, err
	}

	var items []map[string]interface{}
	for rows.Next() {
		var releaseId int
		var releaseName, artistName, releaseYear string
		err := rows.Scan(&releaseId, &releaseName, &releaseYear, &artistName)
		if err != nil {
			return nil, err
		}

		items = append(items, map[string]interface{}{
			"release_id":   releaseId,
			"artist_name":  artistName,
			"release_year": releaseYear,
			"release_name": releaseName,
		})
	}

	return items, nil
}

func sanitizeQuery(query string) string {
	return strings.TrimSpace(query)
}