# Weather Forecast Application

Application - https://weather-forecast-nqmg.onrender.com/

A Rails application that provides weather forecasts using OpenWeatherMap API and Nominatim geocoding service, with Redis caching for improved performance.

## Features

- Location search using postal codes or addresses
- Current weather conditions
- Daily weather forecasts
- Temperature units switching (metric/imperial)
- Response caching with Redis
- Graceful fallback when Redis is unavailable
- Progressive Web App (PWA) support

## Prerequisites

- Ruby 3.4.1 or higher
- Rails 7.x
- Redis server
- OpenWeatherMap API key

## System Dependencies

### Core Dependencies
- Ruby on Rails
- Redis for caching
- HTTParty for API requests
- WebMock (testing)
- RSpec Rails (testing)

### Development Dependencies
- Dotenv for environment management
- Brakeman for security analysis
- Bundler Audit for dependency scanning
- RuboCop for code style enforcement

## Environment variables (.env)

This project uses dotenv for local development. A non-secret example file is
provided at `.env.example`. Do NOT commit your personal `.env` file — the
repository ignores `.env` by default.

Quick setup:

1. Copy the example:

	```bash
	cp .env.example .env
	```

2. Fill in any secret values (for example, `OPENWEATHER_API_KEY`).

3. Start the app (development):

	```bash
	bundle install
	bin/rails server
	```

If you're using Docker or another deployment environment, set the equivalent
environment variables in your container/service configuration instead of
committing them to the repo.

## API Services

### OpenWeatherMap API
- Used for weather data
- Endpoints:
  - Current weather: `/data/2.5/weather`
  - Forecast: `/data/2.5/forecast`
- [API Documentation](https://openweathermap.org/api)

### Nominatim Geocoding
- Used for address/postal code lookup
- Free, open-source geocoding service
- [API Documentation](https://nominatim.org/release-docs/latest/api/Overview/)

## Architecture

### No Database Required
No database is required because the system only needs temporary caching, not persistent storage.
This aligns with proper separation of concerns and avoids unnecessary complexity for a read-only, stateless workload.

### Caching Strategy
- Weather data is cached in Redis for 30 minutes
- Cache keys format: `weather:{postal_code}:v1`
- Automatic fallback to direct API calls if Redis is unavailable

### Core Components

#### Controllers
- `WeatherController`: Handles weather data requests and rendering

#### Services
- `WeatherService`: Interfaces with OpenWeatherMap API
- `GeocodingService`: Handles location lookups via Nominatim
- `ServiceResult`: Standardizes service responses

#### Views
- `weather/_result.html.erb`: Renders weather data

## Object Decomposition & Design Patterns

### Core Design Patterns

#### Adapter Pattern (First-Class Pattern)

External APIs are wrapped with adapters to convert third-party responses into normalized internal objects.

WeatherService

Adapts OpenWeather API response format

Standardizes fields (current, today, next_days)

Handles unit conversion & response cleaning

Uses HttpClient for outgoing requests

GeocodingService

Adapts Nominatim address search response

Normalizes coordinates & postal codes across countries

Handles fallback extraction for postal codes

Uses HttpClient for consistent HTTP behavior

Benefits:

Loose coupling between external APIs & application logic

Easy to swap providers (e.g., Google Maps, AccuWeather)

Standardized error & data structures

#### Facade Pattern (Controller Integration Layer)

The controller acts as a Facade, exposing a simple entry point for complex flows:

For a given address:

Geocode address → lat/long

Fetch weather → with caching & API fallback

Render normalized response

WeatherService.fetch_with_cache(...)


Benefits:

Controllers stay lean & readable

Shields controllers from caching / API / failure logic

Makes high-level orchestration explicit & testable

#### Service Objects Pattern
The application uses the Service Objects pattern to encapsulate business logic and external service interactions:

- **BaseService**
  - Role: Abstract service behavior template
  - Pattern: Template Method & Concern
  - Key Methods: `call`, `perform` (abstract)
  - Features:
    - Standardized validation flow
    - Consistent error handling
    - ActiveModel validations integration

- **ServiceResult**
  - Role: Result object encapsulation
  - Pattern: Value Object
  - States: success/error with optional payload
  - Benefits:
    - Type-safe return values
    - Consistent error handling across services
    - Clear separation of success/failure paths

#### Concern Pattern
Shared behaviors are extracted into concerns:

- **HttpClient**
  - Role: Standardized HTTP interaction
  - Features:
    - JSON parsing
    - Error normalization
    - Consistent headers
    - Rate limiting support

### Object Dependencies

```
WeatherController
├── GeocodingService
│   ├── HttpClient
│   └── ServiceResult
└── WeatherService
    ├── HttpClient
    └── ServiceResult
```

### Caching Strategy Pattern
The application implements a Cache-Aside pattern with Redis:

1. **Write-Around Caching**
   - Weather data cached only on reads
   - 30-minute TTL for freshness
   - Zip code based partitioning

2. **Circuit Breaker Pattern** (Implicit)
   - Graceful Redis failure handling
   - Automatic fallback to direct API calls
   - Error logging and recovery

### Progressive Enhancement Pattern
The frontend implements progressive enhancement:

1. **Base Layer**: Core HTML responses
2. **Enhanced Layer**: JavaScript interactivity
3. **PWA Layer**: Offline capabilities and push notifications

### Error Handling Strategy

1. **Service Layer**
   - Validation errors → ServiceResult
   - API errors → Normalized exceptions
   - Network errors → Retries with backoff

2. **Controller Layer**
   - Graceful degradation
   - User-friendly error messages
   - Cache status transparency

### Future Extension Points

1. **Additional Weather Providers**
   - WeatherService adapter pattern allows easy provider switching
   - Common interface through ServiceResult

2. **Enhanced Caching**
   - Configurable TTLs
   - Regional cache partitioning
   - Background refresh capability

3. **Location Services**
   - Multiple geocoding provider support
   - Reverse geocoding capabilities
   - Location validation rules
- Progressive Web App assets in `views/pwa/`

## Development Guidelines

### Code Style
- Follow Ruby style guide
- Use 2 spaces for indentation
- Keep methods focused and small
- Add meaningful comments for complex logic

### Testing
- Write tests for new features
- Maintain existing test coverage
- Use WebMock for HTTP request stubs
- Test error conditions and edge cases

### Git Workflow
1. Create feature branch
2. Write tests
3. Implement feature
4. Submit pull request
5. Address review feedback

## Troubleshooting

### Common Issues

1. Redis Connection Errors
   - Verify Redis is running
   - Check REDIS_URL environment variable
   - Ensure Redis port is available

2. API Key Issues
   - Verify OPENWEATHER_API_KEY is set
   - Check API key validity
   - Monitor API rate limits

3. Geocoding Failures
   - Verify address format
   - Check Nominatim service status
   - Review API response for error details

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## Maintainers

- [@JAMIANIL3](https://github.com/JAMIANIL3)