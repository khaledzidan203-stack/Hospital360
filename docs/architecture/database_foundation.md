# Hospital360 Database Foundation

## Database Engine

PostgreSQL 16

## Environment

Local Windows development environment

## Database

hospital360

## Schemas

### raw

Purpose:
Immutable/near-source landing layer for source-system data.

### staging

Purpose:
Cleaning, normalization, typing, validation, and transformation layer.

### analytics

Purpose:
Curated analytical/star-schema layer consumed by SQL analysis and Power BI.

## Data Flow

Synthea / Future Sources
→ raw
→ staging
→ analytics
→ Power BI / SQL / Python

## Security Note

No database passwords or credentials are stored in the repository.

## Status

Database foundation created; business tables not yet implemented.
