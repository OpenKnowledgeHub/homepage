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

- einer Quelle (*source*)
- beliebig vielen Zwischenstufen (*intermediate operation*)
- einem Endpunkt (*terminal operation*)

```java
public void runStream() {
    Stream.of(1, 2, 3, 4, 5)                    // <- Quelle
            .map(element -> element * element)  // <- Zwischenstufe
            .forEach(System.out::print);        // <- Endpunkt
    // Output: 1491625
}
```

Java Streams unterliegen eine *lazy evaluation* - das heißt, dass erst dann Elemente in den Zwischenstufen
(*intermediate operation*) verarbeitet werden, wenn das Ergebnis auch wirklich gebraucht wird, also wenn ein Endpunkt
(*terminal operation*) angegeben ist.

## Motivation für `Gatherers`

Wie weiter oben schon festgestellt wurde, hat sich der grundlegende Umfang von dem Stream API seit der Einführung nicht
mehr wirklich verändert. Das betrifft insbesondere die Funktionen der *intermediate operations*, also der
Zwischenstufen. Hier sind bis dato Java Entwicklungen auf die Angebote beschränkt, welche in `java.util.stream.Stream`
definiert werden. Zu den bekannteren Methoden zählen:

- `filter`
- `map`
- `sorted`
- `distinct`

Gerade die Verknüpfung mehrerer dieser Methoden bieten durchaus vielseite Einsatzmöglichkeiten. Jedoch stoßen auch sie
an ihre Grenzen. Wenn wir zum Beispiel eine Liste von Objekten haben und diese nach einem anderen Kriterium als die
Objekt-eigenen `equals` und `hashCode` Implementierung eindeutig (`distinct`) filtern wollen, wäre dies nicht ohne
Umwege möglich.

```java
public void distinctByCustom() {
    Stream.of("maria", "phil", "anna", "jo")    // <- Quelle
            .distinctBy(String::length)         // <- gibt es so nicht
            .forEach(System.out::print);        // <- Endpunkt
    // Erwarteter Output: mariaphiljo
}
```

Oder auch die gerade aus der `SQL` bekannten `window` Funktion, ist nur mit erheblichem Mehraufwand implementierbar:

```java
public void windowFunction() {
    Stream.of(0, 1, 2, 3, 4, 5, 6, 7, 8, 9)     // <- Quelle
            .windowFixed(3)                     // <- gibt es so nicht
            .limit(2)                           // <- Zwischenstufe
            .forEach(System.out::print);        // <- Endpunkt
    // Erwarteter Output: [0, 1, 2][3, 4, 5]
}
```

Um nicht unzählige einzel Problem bezogene zusätzliche Funktionen in der `Stream`-Klasse zu ergänzen, wurde nach einer
generischen Lösung gesucht - die `Stream::gather(Gatherer)` Zwischenstufe soll sich dieser Herausforderung annehmen.

## Aufbau eines `Gatherers`

`Stream::gather` als *intermediate operation* und das `Gatherer` Interface kamen mit Java 22 als *Preview* in die Java
Welt und werden mit Java 24 vollständig released. Wie auch schon bei den bestehenden Zwischenstufen ist eine simple
Definition von einem `Gatherer`:

> A *gatherer* represents a transform of the elements of a
> stream
> ([JEP 461](https://openjdk.org/jeps/461#:~:text=A%20gatherer%20represents%20a%20transform%20of%20the%20elements%20of%20a%20stream))

Jedoch ist hierbei noch im Vorhinein festgelegt, wie genau die Transformation aussehen soll - genau liegen die stärken
das `Gatherer` Aufbaus.

Im Groben besteht ein `Gatherer` aus 4 Ebenen:

- `Integrator`
- `Initializer`
- `Finisher`
- `Combiner`

Nur der `Integrator` ist zwingend notwendig, um einen `Gatherer` zu implementieren. Die drei anderen Ebenen werden für
komplexere Problemstellungen benötigt.

### `Integrator`

Das `Integrator` Interface ist ein `Functional Interface` mit der zentralen Methode `integrate`:

```java

@FunctionalInterface
public interface Integrator<A, T, R> {
    boolean integrate(A state, T element, Downstream<? super R> downstream);
    // . . .
}
```

Der `state` ist der aktuelle Zustand des `Gatherers` und kann verwendet werden, um einen Zustand über die Verarbeitung
einzelner Elemente hinaus zu teilen. Mehr dazu weiter unten. Das `element` ist vom `Upstream` des `Streams` kommende
aktuelle Element, welches transformiert werden soll. Die Referenz auf den `Downstream` hat aus dem
`Functional Interface` die Methode `boolean push(T element)`, welche verwendet wird, um das transformierte Element an
die nächste Ebene im `Stream` zu senden. Als Rückgabewert der `integrate` Methode wird ein `boolean` erwartet. Dieser
zeigt an, ob ein Element an den `Downstream` gesendet wurde oder nicht. Die `Downstream::push` Methode gibt den
booleschen Wert nach der gleichen Logik, nur bezogen auf die nächste Ebene des Streams, zurück.

Mit dem Wissen kann jetzt ein simpler Gatherer geschrieben werden:

```java
public Gatherer.Integrator<Void, Integer, Integer> squaredIntegrator() {
    return Gatherer.Integrator.ofGreedy(
            (state, element, downstream) -> {
                int newElement = element * element;
                return downstream.push(newElement);
            });
}

public void runStreamWithIntegrator() {
    Stream.of(1, 2, 3, 4, 5)
            .gather(Gatherer.of(integrator))
            .forEach(System.out::println);

    // output: 1491625
}
```

Ein besonderes Augenmerk sollte auf `Gatherer.Integrator.ofGreedy` geworfen werden. Ein *greedy*
`Integrator` hat keine eigene Logik, ob er ein weiteres Element aus dem Stream verarbeitet oder nicht. Er verlässt sich
dabei einzig und allein auf den `Downstream`. Diese angabe ermöglicht der JVM unter der Haube etwas an Optimierungen
vorzunehmen. Sollte der Integrator selbst entscheiden, ob ein Element vom `Upstream` verarbeitet wird oder nicht, kann
ein simples `Gatherer.Integrator.of` genutzt werden.

Mit dem Aufrufen von `.gather(Gatherer.of(integrator))` kann jetzt einfach ein neuer `Gatherer` mit dem eigens
definierten `Integrator` für den Stream genutzt werden.

### `Initializer`

Der optionale `Intilizer` wird verwendet, um dem `Gatherer` einen Zustand zu geben. Der im vorherigen Abschnitt gezeigte
`Gatherer` ist zustandslos - er hat keinerlei Informationen neben dem aktuellen Element. Als `Intializer` erwartet das
`Gatherer` Interface einen `Supplier`, welcher den initialen Status (Zustand) erzeugt. Um zum Beispiel einen Zähler zu
implementieren, der nach `x` Elementen stoppt, kann einfach ein `AtomicInteger` genutzt werden:

```java
public Gatherer.Integrator<AtomicInteger, Integer, Integer> squaredIntegratorWithLimit(int limit) {
    return Gatherer.Integrator.of(                                  // (A)
            (state, element, downstream) -> {
                if (state.getAndIncrement() < limit) {
                    int newElement = element * element;
                    return downstream.push(newElement);             // (B)
                } else {
                    return false;                                   // (C)
                }
            });
}

public void runStreamWithIntegrator() {
    Supplier<AtomicInteger> initializer = AtomicInteger::new;
    Gatherer.Integrator<AtomicInteger, Integer, Integer> integrator = squaredIntegratorWithLimit(3);

    Stream.of(1, 2, 3, 4, 5)
            .gather(Gatherer.ofSequential(initializer, integrator)) // (D)
            .forEach(System.out::print);

    // output: 149
}
```

Von dem Grundaufbau hat sich zu dem vorherigen Beispiel nicht viel geändert. Besonders betrachtet werden sollten die
Stellen:

- `(A)`: Da der `Integrator` jetzt *selbst* entscheidet, ob ein Element weiter verarbeitet wird oder nicht, sollte das
  `ofGreedy` durch `of` ersetzt werden.
- `(B)`: Wenn der aktuelle Zustand (`state.getAndIncrement()`) kleiner als das übergebene `limit` ist, wird das Element
  wie schon vorher einfach an den `Downstream` übergeben.
- `(C)`: Wenn der aktuelle Zustand größer oder gleich dem `limit` ist, wird die Verarbeitung des Elements abgelehnt.
- `(D)`: Da nun ein zustandsbehafteter `Gatherer` genutzt wird, welcher keinen `Combiner` hat, darf dieser nicht
  parallel in mehreren `Threads` laufen. Durch `Gatherer.ofSequential` wird dies sichergestellt.

### `Finisher`

### `Combiner`

## Zusammenfassung
