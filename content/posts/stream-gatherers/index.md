---
title: "Stream Gatherers"
date: 2025-01-06T08:57:29+01:00
slug: 2025-01-06-stream-gatherers
type: posts
draft: true
categories:
  - post
tags:
  - java
  - feature
  - jse24
---

## Wo kommen wir her?

Mit der Einführung der `Stream API` in Java SE 8 (insbesondere mit
den [JEP 107 Bulk Data Operations for Collections](https://openjdk.org/jeps/107), [JEP 109 Enhance Core Libraries with Lambda](https://openjdk.org/jeps/109)
und [JEP 126 Lambda Expressions & Virtual Extension Methods](https://openjdk.org/jeps/126)) haben sich die Möglichkeiten
des "Wie" ein Java Projekt umgesetzt wird grundlegend erweitert. Durch die Annäherung und syntaktische Unterstützung von
funktionaler Programmierung eröffnete sich ein ganz neuer Horizont für die Java Welt.

Doch seit dem Start von OpenJDK 8 am 18.03.2014 ([Release Page](https://openjdk.org/projects/jdk8/)) haben sich kaum
nennenswerte Erweiterungen in der API ergeben. Lediglich kleinere Anpassungen wie zum Beispiel der
[JEP 269: Convenience Factory Methods for Collections](https://openjdk.org/jeps/269) in dem Java SE 9 Release haben
kleinere Features in den Umgang mit Streams gebracht.

## Aufbau Streams

Im Wesentlichen besteht ein Stream in Java aus drei Hauptteilen:

- einer Quelle (`source`)
- beliebig vielen Zwischenstufen (`intermediate operation`)
- einem Endpunkt (`terminal operation`)

```

```

## Motivation für `Gatherers`

## Aufbau `Gatherers`

### `Integrator`

### `Initializer`

### `Finisher`

### `Combiner`

## Zusammenfassung
