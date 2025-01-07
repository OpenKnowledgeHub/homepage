---
title: "Stream Gatherers"
date: 2025-01-20T08:57:29+01:00
slug: 2025-01-20-stream-gatherers
type: posts
draft: false
categories:
  - post
tags:
  - java
  - feature
  - jse24
summary: Mit Java 24 kommen die Stream Gatherers aus der Preview Phase und werden offiziell released. Mit den Gatherers wird ein lang gehegter Wunsch vieler Java-Devs wahr - das Schreiben von eigenen Stream intermediate Operationen!
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
Welt und werden mit Java 24 vollständig released. Wie auch schon bei den bestehenden Zwischenstufen ist ein `Gatherer`
recht simple zusammengefasst:

> A *gatherer* represents a transform of the elements of a
> stream
> ([JEP 461](https://openjdk.org/jeps/461#:~:text=A%20gatherer%20represents%20a%20transform%20of%20the%20elements%20of%20a%20stream))

Jedoch ist hierbei noch im Vorhinein festgelegt, wie genau die Transformation aussehen soll - genau hier liegen die
Stärken der `Gatherer`.

Im Groben besteht ein `Gatherer` aus 4 Komponenten:

- `Integrator`
- `Initializer`
- `Finisher`
- `Combiner`

Nur der `Integrator` ist zwingend notwendig, um einen `Gatherer` zu implementieren. Die drei anderen Komponenten werden
für komplexere Problemstellungen benötigt.

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
            .gather(Gatherer.of(squaredIntegrator()))
            .forEach(System.out::println);

    // output: 1491625
}
```

Ein besonderes Augenmerk sollte auf `Gatherer.Integrator.ofGreedy` geworfen werden. Ein *greedy*
`Integrator` hat keine eigene Logik, ob er ein weiteres Element aus dem Stream verarbeitet oder nicht. Er verlässt sich
dabei einzig und allein auf den `Downstream`. Diese Angabe ermöglicht der JVM unter der Haube etwas an Optimierungen
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

Wie der Name `Finisher` schon vermuten lässt, wird dieser Part zum Ende eines `Gatherers` benötigt. Doch wofür genau und
was heißt am Ende? Um dies genauer zu beleuchten, schauen wir uns das Beispiel der `windowFunction` von oben genauer an.
Eine `windowFunction` teilt eine Menge von *x* Elementen in eine Liste von Teilmengen von einer Länge von *y*. So wird
zum Beispiel aus `[1,2,3,4,5,6]` ein `[[1,2], [3,4], [5,6]]`. Was passiert aber, wenn *x* kein Vielfaches von *y* ist?
Also anders formuliert: Was passiert mit dem Zustand eines `Gatherers` nachdem das letzte Element eines Streams
verarbeitet wurde?

Hier kommt der `Finisher` ins Spiel. Dieser ist eine Implementierung des `BiConsumer` Interfaces und erwartet als ersten
Parameter `A` den `state` des `Gatherers` und als zweiten Parameter den `Downstream` des Streams:

```java
BiConsumer<A, Downstream<? super R>> finisher;
```

Mit diesem Wissen kann das Problem der "losen" Elemente bei einer `windowFunction` Implementierung gelöst werden.

```java
public Gatherer.Integrator<List<Integer>, Integer, List<Integer>> windowFunctionIntegrator(int windowSize) {
    return Gatherer.Integrator.of(
            ((state, element, downstream) -> {
                state.add(element);

                if (state.size() == windowSize) { // (A)
                    boolean downstreamResult = downstream.push(List.copyOf(state));
                    state.clear();
                    return downstreamResult;
                }

                return true;
            }));
}

public BiConsumer<List<Integer>, Gatherer.Downstream<? super List<Integer>>> windowFunctionFinisher() {
    return (state, downstream) -> {
        if (!state.isEmpty()) { // (B)
            downstream.push(List.copyOf(state));
            state.clear();
        }
    };
}

public void runGathererWithFinisher() {
    int windowSize = 3;

    Stream.of(1, 2, 3, 4, 5)
            .gather(
                    Gatherer.ofSequential(
                            ArrayList::new, windowFunctionIntegrator(windowSize), windowFunctionFinisher())) // (C)
            .forEach(System.out::print);
    // output: [1, 2, 3][4, 5]
}
```

Im Gegensatz zu den Beispielen weiter oben wurde nun in `(C)` ein `Finisher` dem `Gatherer` bei der Initialisierung
übergeben. `Integrator` und `Finisher` sind dabei recht nah miteinander verzahnt, da der `Finisher` in der Regel auf der
Logik des `Integrators` aufbaut. So auch in diesem Fall: In `(A)` wird geprüft, ob schon genügend Elemente im aktuellen
`state` liegen, ob ein `window` zu füllen. Nur wenn dies der Fall ist, wird das Fenster in Gänze an den `Downstream`
gepushed. Somit kann es passieren, dass am Ende alle Elemente in dem Zustand des `Gatherers` noch Elemente liegen,
welche über den `Finisher` in `(B)` aufgesammelt und ebenfalls an den `Downstream` gesendet werden.

### `Combiner`

Als letzte Komponente für einen `Gatherer` bleibt der `Combiner` übrig. In verschiedenen Endpunkten der `Stream`-Klasse,
wie zum Beispiel der `collect` oder `reduce` Methode, kommt der Begriff *combiner* schon vor. Wie auch an diesen
Stellen, dient der `Combiner` dazu, einen `Gatherer` für die parallele Verarbeitung in mehreren Threads fit zu machen.
Ein `Combiner` wird dann notwendig, wenn ein zustandsbehafteter `Gatherer` in einem parallel ausgeführten Stream genutzt
wird. Ist dies der Fall, behandelt die Implementierung des `Combiner`-Interface die Kombinierung der jeweiligen Zustände
in den unterschiedlichen Threads.

Aus einer Liste von Namen soll der längste Name gefunden werden und für die weitere Verarbeitung in die Stream-Pipline
geschickt werden. Hierzu hält der Zustand des `Gatherers` den aktuell längsten Namen. Der `Finisher` schickt den
längsten Namen dann für die weitere Verarbeitung an den `Downstream` des Streams.

```java
public void runGathererWithCombiner() {
    Stream.of("Anna", "Pete", "Suzanne", "Kay", "Mike")
            .parallel()
            .gather(
                    Gatherer.of(
                            AtomicReference<String>::new, //(A)
                            Gatherer.Integrator.of(
                                    (state, element, downstream) -> {
                                        String currentLongestName = state.get();

                                        if (Objects.nonNull(element)
                                                && (Objects.isNull(currentLongestName)
                                                || element.length() > currentLongestName.length())) {
                                            state.set(element); //(B)
                                        }

                                        return true;
                                    }),
                            (stateA, stateB) -> { //(C)
                                String longestNameFromA = stateA.get();
                                String longestNameFromB = stateB.get();

                                if (longestNameFromA == null) {
                                    return stateB;
                                } else if (longestNameFromB == null) {
                                    return stateA;
                                } else if (longestNameFromA.length() > longestNameFromB.length()) {
                                    return stateA;
                                } else {
                                    return stateB;
                                }
                            },
                            (state, downstream) -> { //(D)
                                String longestName = state.get();

                                if (Objects.nonNull(longestName)) {
                                    downstream.push(longestName);
                                }
                            }))
            .forEach(System.out::println);
    // output: Suzanne
}
```

In dem Code-Snippet oben ist ein `Gatherer` einmal in dem vollen Umfang und allen Unterkomponenten aufgebaut. Es wird
ein paralleler Stream von Namen erstellt. Bei `//(A)` wird der initiale Zustand angelegt. Der `Integrator` in `//(B)`
prüft, ob der aktuelle Namen länger ist, als der im Zustand befindliche. Wenn ja, wird der Zustand mit dem neuen
längsten Namen ersetzt. Erwähnenswert hierbei ist, dass der `Integrator` kein Element in den `Downstream` sendet. Dies
geschieht erst im `Finisher`. Da der `Integrator` alle Elemente annimmt, könnte er auch als `greedy` initialisiert
werden. In `//(C)` wir der `Combiner` implementiert. Er bekommt die jeweiligen Zustände zweiter Threads als Parameter
übergeben und ermittelt den Zustand mit dem längsten Namen. Dieser wird dann zurückgegeben. Schließlich wird im
`Finisher` (`//(D)`) der am Ende aller Elemente im Zustand befindliche Name in den `Downstream` geschickt.

## Zusammenfassung

Die neuen Funktionen der `Gatherer` geben den Stream-APIs von Java ein mächtiges Tool an die Hand. Insbesondere die
Möglichkeiten der freien Konfigurationen bieten erstaunlich viel Freiräume und quasi keine Grenzen für die
Anwendungsfälle. Gerade eine Kombination von `Gatherern` und `Generics` geben gerade für Framework-Entwicklungen viel
Spielraum den Nutzer:innen der Stream API viel "Magie" anzubieten. Aber auch für die klassischen Applikationsanwendungen
können clever genutzte `Gatherer` einen erheblichen Mehrwert im Bereich der Wartbarkeit durch Codereduzierungen bringen.

## Quellen

- [JDK 24 Projekt Seite](https://openjdk.org/projects/jdk/24/)
- [JEP 485: Stream Gatherers](https://openjdk.org/jeps/485)
- [JEP 461: Stream Gatherers (Preview)](https://openjdk.org/jeps/461)
- [Happy Coders: Stream Gatherers - write your own Stream operations](https://www.happycoders.eu/java/stream-gatherers/)