import asyncio
import argparse
from playwright.async_api import async_playwright

async def main(url: str):
    async with async_playwright() as p:
        browser = await p.chromium.launch(
            headless=True,
            args=[
                "--no-sandbox",
                "--disable-setuid-sandbox",
                "--disable-dev-shm-usage",
                "--disable-gpu",
                "--disable-software-rasterizer",
                "--disable-crash-reporter",
                "--disable-extensions",
                "--single-process",
                "--no-zygote"
            ]
        )
        page = await browser.new_page()
        await page.goto(url, wait_until="domcontentloaded", timeout=60000)
        print("Page title:", await page.content())
        await browser.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Fetch a page title with Playwright")
    parser.add_argument("url", help="The URL to open")
    args = parser.parse_args()

    asyncio.run(main(args.url))
