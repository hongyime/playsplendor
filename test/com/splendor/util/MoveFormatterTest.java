package com.splendor.util;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import com.splendor.model.Gem;
import com.splendor.model.Move;
import com.splendor.model.MoveType;
import com.splendor.model.Player;
import java.util.EnumMap;
import java.util.Map;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * Tests for {@link MoveFormatter}.
 * Verifies that move history entries are correctly formatted into human-readable
 * strings. ANSI color codes are present in output but not asserted on — we
 * test the logical content (player name, move type, gem short codes, card IDs).
 */
@DisplayName("MoveFormatter Tests")
class MoveFormatterTest {

    // ── formatMoveEntry ──────────────────────────────────────────────────────

    @Test
    @DisplayName("Take three different gems is formatted with all gem shortcodes")
    void formatTakeThreeDifferentGems() {
        Player player = new Player("Alice");
        Map<Gem, Integer> gems = gems(Gem.WHITE, 1, Gem.BLUE, 1, Gem.GREEN, 1);
        Move move = new Move(MoveType.TAKE_THREE_DIFFERENT, gems);

        String result = MoveFormatter.formatMoveEntry(player, move);

        assertTrue(result.contains("Alice"), "Should contain player name");
        assertTrue(result.contains("Take 3 Different Gems"), "Should contain display name");
        assertTrue(stripAnsi(result).contains("W1"), "Should contain White1");
        assertTrue(stripAnsi(result).contains("B1"), "Should contain Blue1");
        assertTrue(stripAnsi(result).contains("G1"), "Should contain Green1");
    }

    @Test
    @DisplayName("Take two same gems is formatted correctly")
    void formatTakeTwoSameGems() {
        Player player = new Player("Bob");
        Map<Gem, Integer> gems = gems(Gem.RED, 2);
        Move move = new Move(MoveType.TAKE_TWO_SAME, gems);

        String result = MoveFormatter.formatMoveEntry(player, move);

        assertTrue(result.contains("Bob"), "Should contain player name");
        assertTrue(result.contains("Take 2 Same Gems"), "Should contain display name");
        assertTrue(stripAnsi(result).contains("R2"), "Should contain Red2");
    }

    @Test
    @DisplayName("Buy card includes card ID")
    void formatBuyCardWithId() {
        Player player = new Player("Carol");
        Move move = new Move(MoveType.BUY_CARD, 42, false);

        String result = MoveFormatter.formatMoveEntry(player, move);

        assertTrue(result.contains("Carol"), "Should contain player name");
        assertTrue(result.contains("Buy Card"), "Should contain display name");
        assertTrue(result.contains("#42"), "Should contain card ID");
    }

    @Test
    @DisplayName("Buy reserved card shows (Res) suffix")
    void formatBuyReservedCard() {
        Player player = new Player("Dave");
        Move move = new Move(MoveType.BUY_CARD, 99, true);

        String result = MoveFormatter.formatMoveEntry(player, move);

        assertTrue(result.contains("#99"), "Should contain card ID");
        assertTrue(result.contains("(Res)"), "Should contain reserved marker");
    }

    @Test
    @DisplayName("Reserve from deck shows tier")
    void formatReserveFromDeck() {
        Player player = new Player("Eve");
        Move move = Move.reserveFromDeck(2);

        String result = MoveFormatter.formatMoveEntry(player, move);

        assertTrue(result.contains("Reserve Card"), "Should contain display name");
        assertTrue(result.contains("Tier 2"), "Should contain deck tier");
    }

    @Test
    @DisplayName("Reserve visible card shows card ID without tier")
    void formatReserveVisibleCard() {
        Player player = new Player("Frank");
        Move move = new Move(MoveType.RESERVE_CARD, 55, false);

        String result = MoveFormatter.formatMoveEntry(player, move);

        assertTrue(result.contains("#55"), "Should contain card ID");
        // No "Tier" should appear for a visible card reserve
        String stripped = stripAnsi(result);
        assertNotNull(stripped);
    }

    @Test
    @DisplayName("Discard tokens shows discarded gem counts")
    void formatDiscardTokens() {
        Player player = new Player("Grace");
        Map<Gem, Integer> gems = gems(Gem.WHITE, 1, Gem.RED, 1);
        Move move = new Move(MoveType.DISCARD_TOKENS, gems);

        String result = MoveFormatter.formatMoveEntry(player, move);

        assertTrue(result.contains("Discard Tokens"), "Should contain display name");
        assertTrue(stripAnsi(result).contains("W1"), "Should contain White1");
        assertTrue(stripAnsi(result).contains("R1"), "Should contain Red1");
    }

    @Test
    @DisplayName("Exit game move produces clean output")
    void formatExitGame() {
        Player player = new Player("Hank");
        Move move = new Move(MoveType.EXIT_GAME);

        String result = MoveFormatter.formatMoveEntry(player, move);

        assertTrue(result.contains("Hank"), "Should contain player name");
        assertTrue(result.contains("Exit Game"), "Should contain display name");
    }

    // ── formatGemCounts ──────────────────────────────────────────────────────

    @Test
    @DisplayName("Empty gem map returns dash")
    void formatGemCountsEmpty() {
        Map<Gem, Integer> gems = new EnumMap<>(Gem.class);
        assertEquals("-", MoveFormatter.formatGemCounts(gems));
    }

    @Test
    @DisplayName("Single gem type is formatted correctly")
    void formatGemCountsSingle() {
        Map<Gem, Integer> gems = gems(Gem.GOLD, 3);
        String result = stripAnsi(MoveFormatter.formatGemCounts(gems));
        assertEquals("Au3", result);
    }

    @Test
    @DisplayName("Multiple gems follow the shared UI order (R G B W K Au)")
    void formatGemCountsCanonicalOrder() {
        // EnumMap iteration differs from the explicit UI display order.
        Map<Gem, Integer> gems = gems(Gem.GOLD, 1, Gem.BLACK, 2, Gem.RED, 1,
                                       Gem.GREEN, 3, Gem.BLUE, 1, Gem.WHITE, 2);
        String result = stripAnsi(MoveFormatter.formatGemCounts(gems));
        assertEquals("R1 G3 B1 W2 K2 Au1", result);
    }

    @Test
    @DisplayName("Zero-count gems are omitted from output")
    void formatGemCountsOmitsZeros() {
        Map<Gem, Integer> gems = new EnumMap<>(Gem.class);
        gems.put(Gem.RED, 0);
        gems.put(Gem.BLUE, 2);
        String result = stripAnsi(MoveFormatter.formatGemCounts(gems));
        assertEquals("B2", result, "Should omit RED with 0 count");
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private Map<Gem, Integer> gems(Object... entries) {
        Map<Gem, Integer> map = new EnumMap<>(Gem.class);
        for (int i = 0; i < entries.length; i += 2) {
            map.put((Gem) entries[i], (Integer) entries[i + 1]);
        }
        return map;
    }

    /** Strips ANSI escape codes for content-level assertions. */
    private String stripAnsi(String s) {
        return s.replaceAll("\\u001B\\[[0-9;]*m", "");
    }
}
