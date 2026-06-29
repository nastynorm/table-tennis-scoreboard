import { test, expect } from "@playwright/test";
import { setSideScore, advanceGame } from "./util";

// Tests for the features added on top of the original logic:
// serve indicator, yellow cards, cancel timeout, and doubles partner display.
test.describe("added features", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/");
  });

  test.describe("serve indicator", () => {
    test("left serves first and serve flips after two points", async ({
      page,
    }) => {
      // firstServer defaults to player 1 (left side)
      await expect(page.getByTestId("left-serve-indicator")).toHaveClass(
        /amber/,
      );
      await expect(page.getByTestId("right-serve-indicator")).not.toHaveClass(
        /amber/,
      );

      // After two points (any combination) service changes to the other side
      await page.getByTestId("left-button").click();
      await page.getByTestId("right-button").click();

      await expect(page.getByTestId("right-serve-indicator")).toHaveClass(
        /amber/,
      );
      await expect(page.getByTestId("left-serve-indicator")).not.toHaveClass(
        /amber/,
      );
    });

    test("tapping a serve ball sets that side as first server", async ({
      page,
    }) => {
      await expect(page.getByTestId("left-serve-indicator")).toHaveClass(
        /amber/,
      );
      // Tap the right side's serve ball -> right becomes first server
      await page.getByTestId("right-serve-indicator").click();
      await expect(page.getByTestId("right-serve-indicator")).toHaveClass(
        /amber/,
      );
      await expect(page.getByTestId("left-serve-indicator")).not.toHaveClass(
        /amber/,
      );
    });
  });

  test.describe("yellow cards", () => {
    test("can add and remove yellow cards for the left player", async ({
      page,
    }) => {
      await expect(page.getByTestId("left-yellow-cards")).toHaveAttribute(
        "aria-label",
        "0 yellow cards",
      );
      await page.getByTestId("left-add-card").click();
      await expect(page.getByTestId("left-yellow-cards")).toHaveAttribute(
        "aria-label",
        "1 yellow cards",
      );
      await page.getByTestId("left-add-card").click();
      await expect(page.getByTestId("left-yellow-cards")).toHaveAttribute(
        "aria-label",
        "2 yellow cards",
      );
      await page.getByTestId("left-remove-card").click();
      await expect(page.getByTestId("left-yellow-cards")).toHaveAttribute(
        "aria-label",
        "1 yellow cards",
      );
    });

    test("yellow cards are independent per player", async ({ page }) => {
      await page.getByTestId("right-add-card").click();
      await expect(page.getByTestId("right-yellow-cards")).toHaveAttribute(
        "aria-label",
        "1 yellow cards",
      );
      await expect(page.getByTestId("left-yellow-cards")).toHaveAttribute(
        "aria-label",
        "0 yellow cards",
      );
    });
  });

  test.describe("timeout", () => {
    test("can start and cancel a timeout, refunding it", async ({ page }) => {
      await expect(page.getByTestId("left-timeout-button")).toBeVisible();
      await page.getByTestId("left-timeout-button").click();

      await expect(page.getByTestId("cancel-timeout-button")).toBeVisible();
      await page.getByTestId("cancel-timeout-button").click();

      await expect(page.getByTestId("cancel-timeout-button")).not.toBeVisible();
      // Timeout was refunded, so the call-timeout button is available again
      await expect(page.getByTestId("left-timeout-button")).toBeVisible();
    });
  });

  test.describe("match type modal", () => {
    test("New Match menu item opens the modal with four formats", async ({
      page,
    }) => {
      await page.getByTestId("menu-button").click();
      await page.getByTestId("new-match-menu-button").click();
      await expect(page.getByTestId("match-type-modal")).toBeVisible();
      await expect(page.getByTestId("match-type-normal")).toBeVisible();
      await expect(page.getByTestId("match-type-league")).toBeVisible();
      await expect(page.getByTestId("match-type-knockout")).toBeVisible();
      await expect(page.getByTestId("match-type-summer")).toBeVisible();
    });

    test("selecting Normal switches to best-of header, League shows fixtures", async ({
      page,
    }) => {
      await page.getByTestId("menu-button").click();
      await page.getByTestId("new-match-menu-button").click();
      await page.getByTestId("match-type-normal").click();
      await expect(page.getByTestId("match-type-modal")).not.toBeVisible();
      await expect(page.getByTestId("match-center-label")).toContainText(
        "Best of",
      );

      await page.getByTestId("menu-button").click();
      await page.getByTestId("new-match-menu-button").click();
      await page.getByTestId("match-type-league").click();
      await expect(page.getByTestId("match-center-label")).toContainText(
        "Match 1 / 7",
      );
    });

    test("Normal match reaches the match-over screen at 3 games", async ({
      page,
    }) => {
      // Turn off switching sides so the same side keeps winning
      await page.getByTestId("menu-button").click();
      await page.getByTestId("setup-button").click();
      await page.getByTestId("switch-sides-input").uncheck();
      await page.getByTestId("setup-done-button").click();

      // Start a normal (single) match
      await page.getByTestId("menu-button").click();
      await page.getByTestId("new-match-menu-button").click();
      await page.getByTestId("match-type-normal").click();

      // Win three games on the left -> match over (no league fixture advance)
      for (let g = 0; g < 3; g++) {
        await setSideScore(page, "left", 11);
        if (g < 2) {
          await page.getByTestId("new-game-button").click();
        }
      }
      await expect(page.getByTestId("wins-the-match")).toBeVisible();
    });
  });

  test.describe("side-based keyboard", () => {
    test("arrow keys score by physical side after switching ends", async ({
      page,
    }) => {
      // Win game 1 for the left player (Player 1) -> sides switch
      await setSideScore(page, "left", 11);
      await advanceGame(page);
      await expect(page.getByTestId("left-name")).toContainText("Player 2");
      await expect(page.getByTestId("right-name")).toContainText("Player 1");

      // Left arrow scores whoever is on the LEFT (now Player 2), not Player 1
      await page.keyboard.press("ArrowLeft");
      await expect(page.getByTestId("left-score")).toContainText("1");
      await expect(page.getByTestId("right-score")).toContainText("0");

      // Right arrow scores the right side
      await page.keyboard.press("ArrowRight");
      await expect(page.getByTestId("right-score")).toContainText("1");
    });
  });

  test.describe("url startup (Pi kiosk)", () => {
    test("?screen=viewer opens the spectator view", async ({ page }) => {
      await page.goto("/?screen=viewer");
      await expect(page.getByTestId("exit-viewer-button")).toBeVisible();
    });
    test("?screen=control auto-broadcasts", async ({ page }) => {
      await page.goto("/?screen=control");
      await expect(page.getByTestId("broadcasting-indicator")).toBeVisible();
    });
  });

  test.describe("second screen sync", () => {
    test("a viewer window mirrors the controller's score", async ({ page }) => {
      // Controller: start broadcasting and score two points
      await page.getByTestId("menu-button").click();
      await page.getByTestId("broadcast-button").click();
      await expect(page.getByTestId("broadcasting-indicator")).toBeVisible();
      await page.getByTestId("left-button").click();
      await page.getByTestId("left-button").click();

      // Viewer: a second window in the same browser mirrors via BroadcastChannel
      const viewer = await page.context().newPage();
      await viewer.goto("/");
      await viewer.getByTestId("menu-button").click();
      await viewer.getByTestId("view-screen-button").click();
      await expect(viewer.getByTestId("spectator-left-score")).toContainText(
        "2",
        { timeout: 4000 },
      );
      await viewer.close();
    });
  });

  test.describe("layout", () => {
    test("fits a landscape phone with no vertical scroll", async ({ page }) => {
      await page.setViewportSize({ width: 852, height: 393 });
      const scrollH = await page.evaluate(
        () => document.documentElement.scrollHeight,
      );
      const innerH = await page.evaluate(() => window.innerHeight);
      expect(scrollH).toBeLessThanOrEqual(innerH + 1);
      // Names on top, score buttons on the bottom, both visible
      await expect(page.getByTestId("left-name")).toBeVisible();
      await expect(page.getByTestId("left-button")).toBeVisible();
      await expect(page.getByTestId("right-button")).toBeVisible();
    });
  });

  test.describe("presentation mode", () => {
    test("hides controls but keeps the board and keyboard scoring", async ({
      page,
    }) => {
      await expect(page.getByTestId("left-button")).toBeVisible();
      await page.getByTestId("menu-button").click();
      await page.getByTestId("presentation-toggle-button").click();

      // Controls hidden
      await expect(page.getByTestId("left-button")).not.toBeVisible();
      await expect(page.getByTestId("correction-button")).not.toBeVisible();
      await expect(page.getByTestId("left-add-card")).not.toBeVisible();
      await expect(page.getByTestId("left-timeout-button")).not.toBeVisible();
      // Board still shown
      await expect(page.getByTestId("left-score")).toBeVisible();

      // Keyboard still scores (for use with a Bluetooth remote)
      await page.keyboard.press("ArrowLeft");
      await expect(page.getByTestId("left-score")).toContainText("1");

      // Can exit again
      await page.getByTestId("menu-button").click();
      await page.getByTestId("presentation-toggle-button").click();
      await expect(page.getByTestId("left-button")).toBeVisible();
    });
  });

  test.describe("cast help", () => {
    test("opens the cast help modal with A16 guidance", async ({ page }) => {
      await page.getByTestId("menu-button").click();
      await page.getByTestId("cast-help-button").click();
      await expect(page.getByTestId("cast-help-modal")).toBeVisible();
      await expect(page.getByTestId("cast-help-modal")).toContainText("A16");
      await page.getByTestId("cast-help-close").click();
      await expect(page.getByTestId("cast-help-modal")).not.toBeVisible();
    });
  });

  test.describe("doubles", () => {
    test("enabling doubles shows partner names and partner serve ball", async ({
      page,
    }) => {
      await page.getByTestId("menu-button").click();
      await page.getByTestId("setup-button").click();
      await page.getByTestId("doubles-input").check();
      await page.getByTestId("player1-partner-input").fill("Lefty Partner");
      await page.getByTestId("player2-partner-input").fill("Righty Partner");
      await page.getByTestId("setup-done-button").click();

      await expect(page.getByTestId("left-partner-name")).toContainText(
        "Lefty Partner",
      );
      await expect(page.getByTestId("right-partner-name")).toContainText(
        "Righty Partner",
      );
      // Partner serve indicator only exists in doubles
      await expect(
        page.getByTestId("left-serve-indicator-partner"),
      ).toBeVisible();
    });
  });
});
