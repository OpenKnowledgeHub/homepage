---
title: "jSEPA - Teil 1"
date: 2025-03-02T09:00:00+01:00
slug: jsepa-teil1
type: posts
draft: false
categories:
  - post
tags:
  - jsepa
  - refactoring
summary: Das jSEPA Projekt ist etwas in die Jahre gekommen - es ist Zeit für ein umfangreiches Refactoring!

---

Das Projekt [jSEPA](https://github.com/OpenKnowledgeHub/jSEPA) wurde ursprünglich von einem ehemaligen Arbeitskollegen
von mir entworfen und entwickelt. In erster Linie soll das Projekt eine Java Bibliothek anbieten, welche valide
[SEPA](https://en.wikipedia.org/wiki/Single_Euro_Payments_Area) XML Dokumente erstellt, um diese zum Auslösen von
Überweisungen und zum Auslösen vom Einzug mittels Lastschriftverfahren zu nutzen. Beide XML Schemas sind Bestandteil von
dem [ISO 20022](https://www.iso20022.org/) Standard. Für alle Interessierten lege ich die Definition der einzelnen
Nachrichtenbestandteile
der [Zahlungs-Initiierung](https://www.iso20022.org/iso-20022-message-definitions?search=Payments%20Initiation) ans
Herz.

## Wieso sind wir hier?

jSEPA möchte ein einfach zu nutzendes Interface anbieten, damit die Nutzer:innen nicht gezwungen werden, sich mit der -
sagen wir mal - anspruchsvollen XSD auseinander zu setzen. Dieses Ziel scheint erreicht worden zu sein; zumindest für
das Jahr 2014 - das Jahr in dem die ersten Änderungen commited wurden. Es kam wie es kommen musste, die Zeit verstrich
schneller als erwartet und weitere Anpassungen und Aktualisierungen blieben aus. Jetzt ist die Code-Basis weder
einheitlich noch ist die API verständlich. Die Art wie Probleme gelöst wurden scheint aus der Zeit gefallen zu sein und
das größte Problem ist, dass die verwendete XSD Version nicht mehr von den Banken unterstützt wird. Unterm Strich ist
die Library also nicht mehr nutzbar.

## Und jetzt?

Ich bin ein großer Freund und Unterstützer der Open Source Idee / Bewegung / Standard; aber bis heute ist es mir immer
wieder schwergefallen, bei größeren Projekten zu partizipieren. In der meisten Zeit als Java Entwickler habe ich und
nicht öffentlichen Projekten gearbeitet - und dies mehr oder weniger den ganzen Tag. Dies möchte ich ändern. Das
Wichtigste zuerst: das Aufräumen des mir übergebenen Projektes jSEPA.

### Der Plan

Im Kern hat die jSEPA Bibliothek drei zentrale Features:

- das Bereitstellen einer API zum Generieren von XML Dokumenten zum Auslösen von Überweisungen
- das Bereitstellen einer API zum Generieren von XML Dokumenten zum Einziehen von Geldern mittels Lastschrift
- das Bereitstellen einiger Hilfsmethoden
  bezüglich [BIC](https://www.swift.com/standards/data-standards/bic-business-identifier-code)
  und [IBAN](https://www.swift.com/standards/data-standards/iban-international-bank-account-number)

Im ersten Schritt möchte ich die bestehende Code-Basis aufräumen, ohne dabei bestehende Funktionen zu überarbeiten. Dazu
gehören unter anderem nicht genutzte Methoden, überflüssige Kommentare, unklare Dokumentationen.

Im Anschluss soll die API in eine DSL abstrahiert werden, welche mit einer leicht zu verstehenden Dokumentation
ausgestattet wird.

### XSLT anstelle von JAXB2 automatischer Code Generierung

In der aktuellen Implementierung nutzt das jSEPA Projekt ein automatisch generiertes Datenmodell, welches auf Basis der
im Jahre 2014 aktuellen XSD Schemas PAIN_008_001_02 und PAIN_001_003_03 basieren. Dieser Ansatz führt zu einer sehr
großen Anzahl von Boilerplate Code. Methodennamen und Beschreibungen sind aufgrund der kryptischen Abkürzungen im XSD
kaum zu verstehen.

Um dieses Problem anzugehen, möchte ich ein klares und leicht zu verstehendes Datenmodel implementieren, welches dann
via XSLT Style Dokument in das standardisierte Format transferiert wird. Dadurch werden zukünftige Updates im XSD
wesentlich leichter einzubauen, da nur die XSLT Datei angefasst werden muss.

### Hilfsmethoden

Die Klasse BankInformationStore stellt einige statische Hilfsmethoden zur Verfügung, welche in den meisten Fällen mit
einem "Cache" (eine simple Map) von BankInformation Objekten kommuniziert. Diese enthalten Stammdaten von
unterschiedlichen Banken. Aktuell sind nur deutsche Banken unterstützt. Im ersten Schritt werde ich diese Methoden nicht
anfassen - bis klar ist, wie hier weiter vorgehen möchte. Fühlt euch eingeladen Tickets mit Ideen / Meinungen im
[GitHub](https://github.com/OpenKnowledgeHub/jSEPA) Projekt zu eröffnen.


