import { expect, type Page } from "@playwright/test";

// The app now opens on the New Match wizard. Most tests expect the scoreboard,
// so this starts a default Singles match to land on the board.
export async function startDefaultMatch(page: Page) {
  await page.getByTestId("format-singles").click();
  await page.getByTestId("start-match").click();
  await expect(page.getByTestId("left-button")).toBeVisible();
}

export async function setSideScore(
  page: Page,
  side: "left" | "right",
  score: number,
) {
  const buttonEl = page.getByTestId(`${side}-button`);
  const scoreEl = page.getByTestId(`${side}-score`);
  await expect(scoreEl).toContainText("0");

  for (let i = 0; i < score; ++i) {
    await buttonEl.click({ delay: 50 });
  }
  if (await scoreEl.isVisible()) {
    await expect(scoreEl).toContainText(`${score}`);
  } else {
    await expect(page.getByTestId("winner-text")).toBeVisible();
  }
}

export async function increaseSideScore(
  page: Page,
  side: "left" | "right",
  increase: number,
) {
  const buttonEl = page.getByTestId(`${side}-button`);
  const scoreEl = page.getByTestId(`${side}-score`);
  const currentScore = parseInt((await scoreEl.textContent()) ?? "");

  for (let i = 0; i < increase; ++i) {
    await buttonEl.click();
  }
  if (await scoreEl.isVisible()) {
    await expect(scoreEl).toContainText(`${currentScore + increase}`);
  } else {
    await expect(page.getByTestId("winner-text")).toBeVisible();
  }
}

export async function advanceGame(page: Page) {
  await page.getByTestId("new-game-button").click();
  if (
    (await page.getByTestId("left-score").isHidden()) &&
    (await page.getByTestId("start-game-button").isVisible())
  ) {
    try {
      await page.getByTestId("start-game-button").click({ timeout: 2000 });
    } catch (e) {}
  }
}
