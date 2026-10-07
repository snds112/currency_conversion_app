# Application de Conversion de Devises

Un convertisseur de devises simple construit avec Flutter pour un cours d'introduction au développement mobile.

## À propos

Application permettant de convertir entre plusieurs devises via une API publique gratuite.

## Stack technique

- Flutter / Dart
- API : [fawazahmed0/exchange-api](https://github.com/fawazahmed0/exchange-api) — plus de 200 devises

## Lancer l'application

```bash
git clone https://github.com/snds112/currency_conversion_app.git
cd currency_conversion_app
flutter pub get
flutter run
```

## Structure

```
lib/          # Code principal
android/      # Config Android
ios/          # Config iOS
test/         # Tests
pubspec.yaml  # Dépendances
```

## Remarques

Les taux sont mis à jour quotidiennement (limitation de l'API gratuite).
