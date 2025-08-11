---
title: "Moderne Berechtigungssteuerung in Jakarta EE - Teil 1"
date: 2025-08-11T09:00:00+01:00
slug: jakarta-security-teil-1
type: posts
draft: false
categories:
  - post
tags:
  - jakarta
  - security
summary: Die Verwaltung von Berechtigungen ist essenziell für moderne Unternehmensanwendungen, besonders bei wachsender Komplexität und Nutzerzahl. Es wird immer wichtiger, Berechtigungen flexibel, sicher und skalierbar zu gestalten. Diese dreiteilige Artikelserie beleuchtet verschiedene Ansätze zur effizienten Implementierung und Verwaltung von Berechtigungen in Jakarta EE-Anwendungen – von den integrierten Bordmitteln bis hin zu externen, hochverfügbaren Systemen, um den vielfältigen Anforderungen gerecht zu werden.

---

## Moderne Berechtigungssteuerung in Jakarta EE

*Die Verwaltung von Berechtigungen ist ein zentraler Bestandteil moderner Unternehmensanwendungen. Mit steigender
Komplexität der Anwendungen und wachsender Nutzendenbasis wird es immer wichtiger, eine flexible, sichere und
skalierbare Handhabung von Berechtigungen zu etablieren. In dieser dreiteiligen Artikelserie werden verschiedene Ansätze
beleuchtet, wie Berechtigungen in Jakarta EE-Anwendungen effizient implementiert und verwaltet werden können – von der
Nutzung der Bordmittel von Jakarta EE bis hin zu hochverfügbaren, ausgelagerten Systemen.*

## Die In-House Lösung: Berechtigungen in Eigenregie

Freude! Ein neues Projekt startet, nach konzeptioneller Arbeit wird am Datenmodell geschraubt und möglichst schnell
entsteht ein erster Prototyp. Soweit sieht alles gut aus, neue Funktionen und Schnittstellen werden ergänzt und neue
Nutzende werden testweise auf das System gelassen. Etwas Ausprobieren hier, etwas Testen dort, bis der ersten Person
auffällt: „Darf ich das überhaupt machen?“ „Alles halb so wild“, sagt die Projektleitung, „wir haben nur eine Hand voll
Rechte und Rollen, das kann schnell eingebaut werden.“ Zwei Jahre und zahlreiche Releases später steht das Team vor
einem *Big Ball of Mud* [1] aus verworrenen und abhängigen Berechtigungen, und es kommen Fragen auf wie: „Wieso darf
User XYZ diese Schnittelle abrufen?“ oder „Wieso sehe ich diesen Knopf nicht?“

## Woher kommen Berechtigungen?

Berechtigungen haben in unserer Gesellschaft eine bedeutsame Rolle. Fast täglich kommen Menschen in verschiedenen
Situationen mit Berechtigungen in Berührung - sei es mit der Berechtigung ein Auto zu fahren, eine Tür zu öffnen oder
auf eine bestimmte Webseite zuzugreifen. Dabei kommt die Begrifflichkeit aus einem nicht-technischen Kontext. Wird das
Wort Berechtigung in die Einzelteile zerlegt, wird schnell klar, dass ein Zustand beschrieben wird, welcher ein
bestimmtes Recht auf „etwas“ richten lässt [2][3]. Allgemeiner formuliert: Eine Berechtigung beschreibt den Zustand,
dass ein Subjekt durch den Erhalt eines Rechtes legitimiert wird „etwas“ zu tun. Im Folgenden soll ein Blick auf die
Umsetzung dieser Definition in einer Jakarta EE-Applikation geworfen werden.

## Zugriffssteuerung in Jakarta EE

Das Thema Berechtigungen wird im Bereich der Softwareentwicklung oftmals aus dem Blinkwinkel des Datenschutzes und der
Sicherheit gesehen. Daneben gibt es aber durchaus andere Bereiche, welche mittelbar durch das Thema beeinflusst werden.
Zum Beispiel UX- (*User Experience*) und UI- (*User Interface*) Entscheidungen, wie die Platzierung von Inhalten und
Steuerungselementen oder der Umfang von ausgespielten Informationen, werden indirekt durch das Querschnittsthema
Berechtigungen beeinflusst.

Historisch gesehen hat das Thema innerhalb der Jakarta EE (vormals Java EE) Nutzendenschaft keinen guten Stand. Hierbei
lässt sich die Schuld nicht nur bei externen Parteien suchen. Die Entwicklung der Sicherheitsdefinitionen war von Beginn
an undurchsichtig. Ein klar erkennbarer roter Faden hat gefehlt, was dazu führte, dass die sicherheitsbezogenen APIs zum
Teil verteilt oder sogar dupliziert in mehreren Spezifikationen des Jakarta (Java) EE Stacks beschrieben waren (vgl.
Kapitel 1 aus [4]). Einfache Use-Cases benötigten sehr viele Zeilen Code. Dazu kam, dass es trotz der eigentlich
angestrebten Produkt-Unabhängigkeit viele produktbezogene Eigenheiten innerhalb einzelner Applikationsservern gab. Mit
dem JSR-375 [5] wurde das Problem adressiert. Eine einheitliche *Java EE Security API Specification* sollte zentrale
Funktionen im Bereich der Autorisierung, Authentifizierung und allgemeinen Sicherheit einer Enterprise Applikation
vorgeben. Obwohl der JSR aus dem Jahre 2017 ist, findet sich sowohl in der für Jakarta EE 10 genutzten Version 3 der
*Security Spezifikation* [6], als auch in der geplanten Version 4 für das anstehende Jakarta EE 11 Release [7],
folgendes Zitat: (bezugnehmend auf den `SecurityContext`)

> „Various specifications in Jakarta EE provide similar or even identical methods to those provided be [sic] the
> SecurityContext. It is the intention of this specification to eventually supersede those methods and provide a
> cross-specification, platform alternative.“

## Wie ist der aktuelle Stand?

Mit dem ersten Major Release nach der Namespace-Anpassung von Java EE zu Jakarta EE wurde mit der Version 10 das in
diesem Magazin schon oft thematisierte core Profil eingeführt. Mit einem Blick auf die enthaltenen Spezifikationen wird
schnell deutlich, dass sich *Jakarta Security* nicht in dem *core* Profil wiederfindet [8]. Dies liegt zum einen an dem
erklärten Ziel des Profils für den Einsatz in der Cloud möglichst schlank zu sein. Zum anderen gibt es durch die weiter
oben beschriebene zerfahrene Entwicklung im Bereich der Sicherheits-APIs von Jakarta EE innerhalb der *Jakarta RESTful
Web Services* Spezifikation eigene, durch die Praxis etablierte Mechanismen für den Sicherheitsaspekt im *REST*-Kontext.

Im Zuge dieser Artikelserie soll ein Blick auf die dedizierten Spezifikationen im Bereich der „Sicherheit“ gewagt
werden. Aus diesem Grund wird die gesamte Jakarta EE 10 Plattform betrachtet. Konkret sollten hier drei Spezifikationen
hervorgehoben werden:

- *Jakarta Authentication* [9]
- *Jakarta Authorization* [10]
- und die schon angesprochene *Jakarta Security* [6]

Die beiden Spezifikationen *Authentication* und *Authorization* definieren hierbei allgemeinere „low-level“ Service
Provider Interfaces (SPI). Im Zuge einer Applikationsentwicklung ist ein direkter Kontakt mit den beiden Spezifikationen
nicht zwingend notwendig. Vielmehr dienen die Definitionen aus *Jakarta Security* der direkten Nutzung in
Applikations-Code. An einigen Stellen kann die Spezifikation als niedrigschwelliger Kleber für die darunter liegenden
*Authentication* und *Authorization* Spezifikationen verstanden werden. Hierbei hat *Jakarta Security* einen starken
Fokus auf webbasierte Anwendungen.

## Authentication vs Authorization

Um bei der Entwicklung nicht die beiden oft in einem Satz fallenden Begriffe *Authentication* und *Authorization* zu
verwechseln, ergibt es Sinn, diese klar voneinander zu differenzieren:

**Authentication**: Im Zuge der Authentifizierung wird geprüft und sichergestellt, dass die andere Partei, wirklich die
ist, welche sie vorgibt zu sein. In der Regel wird dazu ein „Etwas“ abgefragt, welches nur die andere Partei wissen
kann - zum Beispiel ein Passwort, Secret Key oder eine PIN. (vgl. S. 71 aus [4])

**Authorization**: Im Zuge der Autorisierung wird geprüft, ob das zuvor authentifizierte Subjekt die Berechtigung hat,
auf eine Ressource zuzugreifen oder eine bestimmte Aktion auszuführen.

Der Schwerpunkt dieser Serie soll auf den Berechtigungen - der *Authorization* - liegen. Allen an der Authentifizierung
interessierten Menschen sei der Einstieg mit Jakarta unter [11] ans Herz gelegt. Insbesondere die beiden Interfaces
`IdentityStore` und `HttpAuthenticationMechanism` bieten hierfür sehr flexible und einfache Möglichkeiten.

## Modelle der Zugriffssteuerung

Im Laufe der Jahre haben sich in der IT und zum Teil auch analogen Welt zahlreiche Modelle zur Handhabung von
Zugriffsberechtigungen entwickelt. Hierbei muss oft zwischen dem Aufwand der Umsetzung und der Vielfalt an
Einsatzoptionen abgewogen werden. Auf der einen Seite gibt es das aus dem Militär bekannte *Mandatory Access Control* (
MAC) Model, bei welchem Ressourcen in starre Schubladen wie „ohne Restriktionen“, „vertraulich“ und „streng vertraulich“
geclustert werden. Personen und Organisationen bekommen eine feste Freigabestufe, anhand welcher geprüft werden kann, ob
ein Zugriff gewährt wird oder nicht. Auf der anderen Seite gibt es moderne Modelle, wie die *Risk Adaptive Access
Control* [12], welche in Echtzeit, verschiedenste Parameter von Nutzungsverhalten, über Standort und Gewohnheiten
analysieren und oftmals mittels KI (Künstliche Intelligenz) bewerten, um so dynamische Entscheidungen, ob Zugriff
gewährt wird oder nicht, treffen zu können. Für Anwendungsentwicklungen liegt die Wahl des Zugriffmodells oftmals in der
Mitte der beiden Extremen. Die Entscheidung, welches Modell am Ende genutzt werden sollte, hängt wie fast immer von den
konkreten Anforderungen und Gegebenheiten ab.

Als eines der bekannteren Modelle hat sich die *Role-Based Access Control* (RBAC) in der IT etabliert. Dies liegt
maßgeblich an der aus der realen Welt leicht nachvollziehbaren Übertragbarkeit. Bei RBAC werden als zentrale Einheiten
Rollen (*Roles*) definiert. Diese bündeln in der Regel aus der fachlichen Domäne abgeleitete Rechte, welche ermöglichen
bestimmte Daten einsehen zu können oder manipulieren zu dürfen. So kann beispielsweise eine IT-Administratorin eines
Unternehmens auf die Konfiguration des E-Mail Servers zugreifen, jedoch bleiben ihr Einblicke in Kundendaten verwehrt.
Auf der anderen Seite darf ihr Kollege in der Kundenbetreuung Informationen zu einem Kunden einsehen, die Konfiguration
des Mail Servers bleibt für ihn aber verschlossen. So werden auf der einen Seite Ressourcen und Aktionen mit einer Rolle
als Bedingung in Verbindung gebracht. Auf der anderen Seite wird ein Subjekt (Mensch oder Maschine) einer oder mehreren
Rollen zugeordnet. Versucht nun das Subjekt auf die gesicherte Ressource zuzugreifen, wird zuerst geprüft, ob die als
notwendig definierte Rolle dem Subjekt zugeordnet wurde. Ist dies der Fall, wird der Zugriff gewährt.

## Das `Principal` Interface

*Jakarta Security* bietet als Grundgerüst für die Autorisierung ebenfalls die *Role-Based Access Control* an. Hierbei
spielt das `Principal` Interface aus dem Java SE `java.security` Package eine zentrale Rolle. Nach erfolgreicher
Authentifizierung wird eine Instanz der konkreten Implementierung `CallerPrincipal` initialisiert. Dieses repräsentiert
den aktuell - oftmals bezogen auf den aktuellen HTTP-Request - authentifizierten Client. Der `CallerPrincipal` wird mit
einem Set aus zugehörigen Rollen im Zuge der Authentifizierung über das *Security* Modul propagiert. Die
`CallerPrincipal` Klasse ist simpel gehalten und implementiert die eine aus dem `Principal` stammende Methode
`public String getName()`. *Jakarta Security* erlaubt es aber auch eigene Sub-Klassen von `CallerPrincipal` zu nutzen.
Diese können somit zusätzliche applikationsspezifische Attribute enthalten (siehe dazu Listing 1).

```java
package org.openknowlegdehub.jakarta.security.config;

import jakarta.security.enterprise.CallerPrincipal;

public class UserPrincipal extends CallerPrincipal {
    private final long departmentId;

    public UserPrincipal(String name, long departmentId) {
        super(name);
        this.departmentId = departmentId;
    }

    public long getDepartmentId() {
        return departmentId;
    }
}
```

*Listing 1: Eigene CallerPrincipal Klasse*

## Deklarative Steuerung

Um in Jakarta Applikationen bestimmte Ressourcen oder Methoden abzusichern, kann in der Entwicklung auf die deklarative
Konfiguration zurückgegriffen werden. Hierbei werden entweder mittels Angaben in XML Format oder per Annotationen dem
Applikationsserver mitgeteilt, welche Bedingungen erfüllt sein müssen, um auf einen bestimmten Teil von Code zugreifen
zu dürfen.

## Angaben in der `web.xml`

In dem Deployment Descriptor `web.xml` können mittels der Angabe von `<security-constraint>`-Elementen solche Regeln
definiert werden. In Listing 2 ist dies von Zeile 10 bis 18 zu sehen. Hierbei wird als `<web-resource-collection>`
festgelegt, welche Ressource betroffen ist. In diesem Fall betrifft dies alle Web-Endpunkte, welche mit `/api/`
beginnen. In dem `<auth-constraint>`-Element wird dann die eigentliche Regel definiert. In dem Beispiel aus Listing 2
muss der aktuell authentifizierte `Principal` der Rolle user angehören. Ist dies nicht der Fall, würde der Request mit
einem entsprechenden Fehlercode abgelehnt werden. Unterhalb der Bedingung werden alle für die Applikation notwendigen
Rollen angegeben. Im dem konkreten Listing gibt es nur die Rolle `user`.

```xml

<security-constraint>
    <web-resource-collection>
        <web-resource-name>Protected Ressource</web-resource-name>
        <url-pattern>/api/*</url-pattern>
    </web-resource-collection>
    <auth-constraint>
        <role-name>user</role-name>
    </auth-constraint>
</security-constraint>

<security-role>
    <role-name>user</role-name>
</security-role>
```

*Listing 2: Eine web.xml mit Sicherheitstregeln*

## Angaben mittels Annotationen

Die Konfiguration der Anwendung über XML-Dateien ist schon seit geraumer Zeit nicht die Lieblingsbeschäftigung einiger
Kolleg:innen. Zumal Jakarta EE (Java EE) nicht zuletzt dadurch ein etwas eingestaubtes Image bekommen hat. Schon seit
einigen Jahren wird versucht neben der XML-Konfiguration eine zusätzliche codenahe Möglichkeit der Verwaltung für die
Applikationsentwicklungen anzubieten. Mit Hilfe der Nutzung von Annotationen können Metainformation eng mit dem
eigentlichen Code verbunden werden. Dies gilt gleichermaßen für die Autorisierungsverwaltung innerhalb einer Jakarta
Anwendung.

Die aus der *Jakarta Annotation Spezifikation* [13] stammenden Annotationen

- `@RunAs`
- `@RolesAllowed`
- `@PermitAll`
- `@DenyAll`
- `@DeclareRoles`

können allesamt genutzt werden, um die Zugriffe innerhalb der Anwendung zu steuern. `@DeclareRoles` wird verwendet, um
wie in Listing 2 die für die Applikation gegebenen Rollen zu definieren. Diese können verteilt über mehrere Klassen oder
an einer zentralen Stelle angegeben werden. Hier bietet sich zum Beispiel die `jakarta.ws.rs.core.Application` an -
sofern *Jakarta RESTful Web Services* in der Anwendung genutzt werden. Listing 3 zeigt dies beispielhaft für die Rollen
`user` und `admin`.

```java
package org.openknowlegdehub.jakarta.security.rest;

import jakarta.annotation.security.DeclareRoles;
import jakarta.ws.rs.ApplicationPath;
import jakarta.ws.rs.core.Application;

@ApplicationPath("api")
@DeclareRoles({"user", "admin"})
public class RestApplication extends Application {
}
```

*Listing 3: Mit Hilfe von `@DeclareRoles` werden anwendungsrelevante Rollen definiert*

`@PermitAll` und `@DenyAll` schaltet den Zugriff entweder für alle frei oder blockiert ihn für alle Principals. Wie die
Annotation `@RolesAllowed` vermuten lässt, können Rollen angegeben werden, welche in dem Set der Rollen des aktuell
autorisierten Clients vorhanden sein müssen. Alle drei Annotationen können sowohl auf Klassen-, als auch Methoden-Ebene
deklariert werden. Dabei **überschreibt** die Methoden Konfiguration eine mögliche Klassen-Konfiguration.

```java

@Path("/dummy")
@Produces(MediaType.APPLICATION_JSON)
@RolesAllowed("user")
public class DummyRestController {

    public record DummyResponse(String message) {
    }

    public record DummyRequest(String message) {
    }

    @GET
    public DummyResponse getDummy() {
        return new DummyResponse("GET /dummy");
    }

    @POST
    @RolesAllowed("admin")
    @Consumes(MediaType.APPLICATION_JSON)
    public DummyResponse postDummy(DummyRequest dummyRequest) {
        return new DummyResponse("POST /dummy with message %s".formatted(dummyRequest.message));
    }
}
```

In dem Listing 4 wird auf Klassenebene definiert, dass die Rolle user notwendig ist, um auf die Ressourcen in diesem
REST-Controller zuzugreifen. Bei der Implementierung der POST-Methode wird diese Konfiguration überschrieben. Um an den
Endpunkt `.../dummy` einen POST zu senden, muss der aktuelle Principal in der Rolle `admin` sein. Andernfalls wird der
Request abgelehnt.

In den Beispielen oben wurde die deklarative Konfiguration lediglich in dem Anwendungsfall von *REST* gezeigt. Die
Nutzung funktioniert identisch innerhalb von *Jakarta Enterprise Beans* (EJB) [14].

## Programmatische Steuerung

Auch wenn die Verwendung der oben beschriebenen Methodiken je nach Komplexität der Anwendung schon genügen mag, kommt
die einfache Reduktion auf Rollen gerade in größeren Anwendungen an ihre Grenzen. In den Beispielen wurden die
Zugriffsregeln lediglich konfigurativ beschrieben. Der Anwendungsserver hat aus diesen Konfigurationen im Zusammenspiel
von *Jakarta Security* und *Jakarta Authorization* den eigentlichen Code für die Prüfung abgeleitet. Die *Security*
Spezifikation bietet noch ein weiteres mächtiges Interface, welches die Handhabung der Zugriffsprüfung feingranularer in
die Hände des Anwendungscodes legt: das `SecurityContext` Interface.

Eine konkrete Implementierung des Interfaces kann mittels *Contexts and Dependency Injection* (CDI) mindestens in den
vom Servlet- und EJB-Container verwalteten Klassen geladen werden. Das Interface stellt dabei Methoden zur Verfügung, um
Informationen zu dem aktuellen autorisierten `Principal` zu erhalten. Mit `boolean isCallerInRole(String role)` kann
geprüft werden, ob der aktuelle Client Mitglied in einer bestimmten Gruppe ist. Darüber hinaus kann mit
`Principal getCallerPrincipal()` bzw. `<T extends Principal> Set<T> getPrincipalsByType(Class<T> pType)` der aktuelle
`Principal` geladen werden. Dabei bietet die `getPrincipalsByType` Methode an, den schon weiter oben beschriebenen
applikationseigenen `Principal` zu laden. In Listing 5 wird erst geprüft, ob es einen aktuell authentifizierten
`UserPrincipal` gibt. Wenn es eine Instanz gibt, kann direkt auf die zusätzlichen Attribute zugegriffen werden.

```java
Optional<UserPrincipal> optionalUserPrincipal =
        securityContext.getPrincipalsByType(UserPrincipal.class)
                .stream()
                .findAny();

if (optionalUserPrincipal.isPresent()) {
    UserPrincipal userPrincipal = optionalUserPrincipal.get();
    long departmentId = userPrincipal.getDepartmentId();
    
    // do some checks with the departmentId
}
```

*Listing 5: Nutzen des eigenen Principals*

## Fazit

In der Jakarta-Welt erfreut sich das Thema der Authentifizierung und Autorisierung keiner allzu großen Beliebtheit.
Historische Entwicklungen, welche zu lange nebeneinander und ohne gemeinsames Ziel implementiert wurden, haben die
Akzeptanz unter der Nutzendenschaft in diesem Bereich nachhaltig geschadet. Der JSR-375 [5] hat den Grundstein gelegt,
um mit diesem Image aufzuräumen. Mit der für Jakarta EE 11 geplanten Version 4 von der *Security* Spezifikation, gibt es
ein erprobtes und solides Grundgerüst, auf welchem sich die Sicherheit der eigenen Anwendung gut aufbauen lässt. Wie so
oft in der community-getriebenen Open-Source Welt: Die positive Weiterentwicklung, insbesondere die Vereinheitlichung
über alle Spezifikationen hinweg, hängt maßgeblich von der Mitwirkung und Ruckmeldung aller ab.

Im nächsten Teil der Serie soll ein Blick auf den *Open Policy Agent* [15] geworfen werden. Insbesondere soll
beschrieben werden, wie dieser aufbauend auf *Jakarta Security* angebunden und gewinnbringend genutzt werden kann.

## Quellen

- [1] Brian Foote und Joseph Yoder (1999): Big Ball of Mud. University of Illinois at
  Urbana-Champaign, http://www.laputan.org/mud/
- [2] Cornelsen Verlag GmbH (2025): Duden Online Berechtigung. https://www.duden.de/rechtschreibung/Berechtigung
- [3] Digitales Wörterbuch der deutschen Sprache (2025): Präfix be-. https://www.dwds.de/wb/be-
- [4] Arjan Tijms, Teo Bais und Werner Keil (2022): The Definitive Guide to Security in Jakarta EE. Apress Media, New
  York.
- [5] Inc. Oracle America (2017): Java EE Security API Specification Version
  1.0. https://javaee.github.io/securityspec/spec/jsr375-spec.html
- [6] Eclipse Foundation (2022): Jakarta Security Version
  3.0. https://jakarta.ee/specifications/security/3.0/jakarta-security-spec-3.0.html
- [7] Eclipse Foundation (2024): Jakarta Security Version
  4.0. https://jakarta.ee/specifications/security/4.0/jakarta-security-spec-4.0
- [8] Eclipse Foundation (2022): Release Jakarta EE 10.
  https://jakarta.ee/release/10/.
- [9] Eclipse Foundation: Jakarta Authentication. https://jakarta.ee/specifications/authentication/.
- [10] Eclipse Foundation: Jakarta Authorization. https://jakarta.ee/specifications/authorization/.
- [11] Eclipse Foundation: Jakarta Security, Jakarta Authorization, and Jakarta Authentication
  Explained. https://jakarta.ee/learn/specification-guides/security-authorization-and-authentication-explained/
- [12] National Institute of Standards und Technology: Risk Adaptive (Adaptable) Access
  Control. https://csrc.nist.gov/glossary/term/Risk_Adaptive_Adaptable_Access_Control.
- [13] Eclipse Foundation (2021): Jakarta Annotations Version
  2.1.0. https://jakarta.ee/specifications/annotations/2.1/annotations-spec-2.1.
- [14] Eclipse Foundation: Jakarta Enterprise Beans 4.0.
  https://jakarta.ee/specifications/enterprise-beans/4.0/jakarta-enterprise-beans-spec-core-4.0.
- [15] Cloud Native Computing Foundation: Open Policy Agent.
  https://www.openpolicyagent.org/.

> alle angegebenen URLs wurde das letzte Mal am 04.02.2025 besucht.
> Der Artikel ist zuerst im [Java aktuell Magazin 2/2025](https://www.ijug.eu/de/java-aktuell/zeitschrift/java-aktuell-archiv/detailansicht-java-aktuell/java-aktuell-02-2025/) erschien.


