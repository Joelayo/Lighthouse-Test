const puppeteer = require('puppeteer');
const fs = require('fs');
const { URL } = require('url');

(async () => {
    const urls = process.argv.slice(2); // Accept multiple URLs from the command line
    if (urls.length === 0) {
        console.error('Please provide URLs to test.');
        process.exit(1);
    }

    const date = new Date();
    const timestamp = date.toISOString().replace(/[:.]/g, '-'); // Format for filenames

    for (const url of urls) {
        console.log(`Starting tests for: ${url}`);
        const parsedUrl = new URL(url);
        const hostname = parsedUrl.hostname;

        // **Sanitize path to use in filenames**
        let sanitizedPath = parsedUrl.pathname.replace(/[^a-zA-Z0-9]/g, '-'); 
        if (sanitizedPath.length > 100) sanitizedPath = sanitizedPath.substring(0, 100);

        for (let i = 1; i <= 2; i++) {
            console.log(`Running test ${i} for: ${url}`);
            
            const browser = await puppeteer.launch({
                headless: false,  // Set to false to avoid bot detection issues
                args: [
                    '--no-sandbox',
                    '--disable-setuid-sandbox',
                    '--disable-dev-shm-usage',
                    '--disable-extensions',
                    '--disable-gpu',
                ],
            });

            const page = await browser.newPage();

            // **Set a real User-Agent to bypass bot detection**
            await page.setUserAgent(
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36'
            );

            // Dynamically import Lighthouse
            const { default: lighthouse } = await import('lighthouse');

            const { lhr, report } = await lighthouse(url, {
                port: new URL(browser.wsEndpoint()).port,
                output: 'html',
                logLevel: 'info',
            });

            // **Create a unique filename using sanitized path**
            const reportFilename = `report_${hostname}${sanitizedPath}_test${i}_${timestamp}.html`;
            const reportHtml = report;
            
            // Save report for each test
            // const reportFilename = `report_${hostname}_test${i}_${timestamp}.html`;
            // const reportHtml = report;

            if (!fs.existsSync('./lighthouse-results')) {
                fs.mkdirSync('./lighthouse-results');
            }
            fs.writeFileSync(`./lighthouse-results/${reportFilename}`, reportHtml);

            console.log(`Test ${i} report saved: ./lighthouse-results/${reportFilename}`);
            await browser.close();
        }
    }

    console.log('All tests completed.');
})();
