import XCTest
@testable import ReproductorPersonal

final class TrackAuthenticityTests: XCTestCase {
    private let artist = [ArtistRef(name: "Artista", browseID: "UCartista")]

    private func video(_ title: String, author: String = "Canal", type: MusicVideoType? = nil,
                       refs: [ArtistRef]? = nil, channelID: String? = nil) -> Video {
        Video(id: "aaaaaaaaaaa", title: title, author: author, durationText: "3:30",
              channelID: channelID, artistRefs: refs, musicVideoType: type)
    }

    private func tier(_ video: Video, expected: ArtistIdentity? = nil) -> AuthenticityTier {
        TrackAuthenticity.assess(video, expected: expected).tier
    }

    func testTiersAreOrderedFromMostToLeastTrustworthy() {
        XCTAssertLessThan(AuthenticityTier.verifiedCatalog, .officialChannel)
        XCTAssertLessThan(AuthenticityTier.officialChannel, .unknown)
        XCTAssertLessThan(AuthenticityTier.unknown, .suspicious)
    }

    func testAIMarkersAreAlwaysSuspicious() {
        XCTAssertEqual(tier(video("Bachata Rosa (AI Cover)")), .suspicious)
        XCTAssertEqual(tier(video("Ojalá que llueva café – versión IA")), .suspicious)
        XCTAssertEqual(tier(video("Despacito [AI]")), .suspicious)
        XCTAssertEqual(tier(video("Tema hecho con IA")), .suspicious)
        XCTAssertEqual(tier(video("Canción generada con IA")), .suspicious)
        XCTAssertEqual(tier(video("Suno AI song 2026")), .suspicious)
        XCTAssertEqual(tier(video("Tema", author: "Voz IA Oficial")), .suspicious)
        XCTAssertEqual(tier(video("Inteligencia artificial canta salsa")), .suspicious)
    }

    func testAIMarkerOverridesCatalogSignals() {
        XCTAssertEqual(tier(video("Tema (AI)", type: .atv, refs: artist)), .suspicious)
    }

    func testImitationMarkersAreSuspiciousWithoutCatalogData() {
        XCTAssertEqual(tier(video("Karaoke Shakira")), .suspicious)
        XCTAssertEqual(tier(video("Soda Stereo Tributo")), .suspicious)
        XCTAssertEqual(tier(video("Tema en estilo de Juan Luis Guerra")), .suspicious)
        XCTAssertEqual(tier(video("Parodia de un éxito")), .suspicious)
        XCTAssertEqual(tier(video("Despacito nightcore")), .suspicious)
        XCTAssertEqual(tier(video("Despacito slowed + reverb")), .suspicious)
        XCTAssertEqual(tier(video("Despacito 8D Audio")), .suspicious)
        XCTAssertEqual(tier(video("Tema", author: "Tribute Band Channel")), .suspicious)
        XCTAssertEqual(tier(video("If Elvis sang Despacito")), .suspicious)
        XCTAssertEqual(tier(video("Si Shakira cantara salsa")), .suspicious)
    }

    func testCatalogTrackWithCoverInItsRealTitleStaysVerified() {
        XCTAssertEqual(tier(video("Cover Me", type: .atv, refs: artist)), .verifiedCatalog)
        XCTAssertEqual(tier(video("Tributo a la vida", type: .atv, refs: artist)), .verifiedCatalog)
    }

    func testOfficialMusicVideoWithIdentifiedArtistIsVerified() {
        XCTAssertEqual(tier(video("Tema (Official Video)", type: .omv, refs: artist)), .verifiedCatalog)
    }

    func testCatalogTypeWithoutIdentifiedArtistIsNotVerified() {
        XCTAssertEqual(tier(video("Tema", type: .atv, refs: nil)), .unknown)
        XCTAssertEqual(tier(video("Tema", type: .atv, refs: [ArtistRef(name: "Artista", browseID: nil)])), .unknown)
    }

    func testUserGeneratedContentWithoutMarkersIsUnknown() {
        XCTAssertEqual(tier(video("Tema", type: .ugc, refs: artist)), .unknown)
        XCTAssertEqual(tier(video("Tema normal")), .unknown)
    }

    func testWholeWordMatchingAvoidsFalsePositives() {
        XCTAssertEqual(tier(video("Discover Weekly Mix")), .unknown)
        XCTAssertEqual(tier(video("Ai Se Eu Te Pego", author: "Michel Teló")), .unknown)
        XCTAssertEqual(tier(video("Recover the Sun")), .unknown)
    }

    func testOfficialChannelSignals() {
        XCTAssertEqual(tier(video("Tema", author: "Juan Luis Guerra - Topic")), .officialChannel)
        XCTAssertEqual(tier(video("Tema", author: "ArtistaVEVO")), .officialChannel)
        XCTAssertEqual(tier(video("Tema", author: "Artista ✓")), .officialChannel)
        XCTAssertEqual(tier(video("Tema", author: "Cualquier canal", channelID: "UCartista"),
                            expected: ArtistIdentity(name: "Artista", browseIDs: ["UCartista"])), .officialChannel)
    }

    func testMusicNoteInChannelNameIsNotAnOfficialSignal() {
        XCTAssertEqual(tier(video("Tema", author: "♫ Música Romántica ♫")), .unknown)
    }

    func testMatchesArtistByIDByExactNameAndRejectsLookalikes() {
        let expected = ArtistIdentity(name: "Maná", browseIDs: ["UCmana"])
        let byID = video("Tema", refs: [ArtistRef(name: "Otro nombre", browseID: "UCmana")])
        let byName = video("Tema", author: "Maná - Topic")
        let lookalike = video("Tema", author: "Manáfans")
        let otherArtist = video("Tema", type: .atv, refs: [ArtistRef(name: "Shakira", browseID: "UCshakira")])
        XCTAssertEqual(TrackAuthenticity.assess(byID, expected: expected).matchesArtist, true)
        XCTAssertEqual(TrackAuthenticity.assess(byName, expected: expected).matchesArtist, true)
        XCTAssertEqual(TrackAuthenticity.assess(lookalike, expected: expected).matchesArtist, false)
        XCTAssertEqual(TrackAuthenticity.assess(otherArtist, expected: expected).matchesArtist, false)
    }

    func testMatchesArtistFindsOneArtistAmongSeveral() {
        let collab = video("Una Fotografía", type: .atv, refs: [
            ArtistRef(name: "Bonny Cepeda", browseID: "UCbonny"),
            ArtistRef(name: "Johnny Ventura", browseID: "UCjohnny"),
            ArtistRef(name: "Juan Luis Guerra", browseID: "UCjlg")])
        let expected = ArtistIdentity(name: "Juan Luis Guerra", browseIDs: ["UCjlg"])
        XCTAssertEqual(TrackAuthenticity.assess(collab, expected: expected).matchesArtist, true)
    }

    func testMatchesArtistIsNilWhenNoArtistIsExpectedOrThereIsNoData() {
        XCTAssertNil(TrackAuthenticity.assess(video("Tema"), expected: nil).matchesArtist)
        let anonymous = Video(id: "aaaaaaaaaaa", title: "Tema", author: "Autor desconocido")
        XCTAssertNil(TrackAuthenticity.assess(anonymous, expected: ArtistIdentity(name: "Artista")).matchesArtist)
    }

    func testAssessmentExplainsItsDecision() {
        let assessment = TrackAuthenticity.assess(video("Tema (AI Cover)"))
        XCTAssertFalse(assessment.reasons.isEmpty)
        XCTAssertTrue(assessment.reasons.allSatisfy { !$0.isEmpty })
    }
}
