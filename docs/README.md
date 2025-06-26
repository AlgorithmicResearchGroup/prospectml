# ProspectML Static Site

This is the static marketing and pricing site for ProspectML. It's designed to be hosted on any static hosting service (GitHub Pages, Netlify, Vercel, S3, etc.).

## Structure

```
static_site/
├── index.html          # Landing page
├── pricing.html        # Pricing and purchase page
├── css/
│   ├── style.css       # Base styles (copied from main app)
│   ├── landing.css     # Landing page styles (copied from main app)
│   ├── pricing.css     # Pricing page specific styles
│   └── professional.css # Professional override styles (optional)
└── README.md           # This file
```

## Setup

### 1. Update Payment Links

Edit `pricing.html` and replace:
- `YOUR_STRIPE_LINK` with your actual Stripe payment link
- Email addresses with your actual sales email
- Any other placeholder content

### 2. Deploy Options

#### GitHub Pages
1. Push to a `gh-pages` branch or configure Pages to use main branch
2. Enable GitHub Pages in repository settings
3. Site will be available at `https://[username].github.io/[repo-name]`

#### Netlify
1. Drag and drop the `static_site` folder to Netlify
2. Or connect your GitHub repo and set build directory to `static_site`

#### Vercel
```bash
cd static_site
vercel
```

#### S3 + CloudFront
```bash
aws s3 sync . s3://your-bucket-name --delete
aws cloudfront create-invalidation --distribution-id YOUR_DIST_ID --paths "/*"
```

#### Simple HTTP Server (for testing)
```bash
cd static_site
python -m http.server 8000
# Visit http://localhost:8000
```

## Customization

### Style Options
The site includes three visual styles:
1. **Cyberpunk** (default): The original futuristic tech aesthetic with full neon effects
2. **Refined** (current): Same cool aesthetic but toned down - less aggressive, more readable
3. **Professional**: Clean, corporate design for enterprise clients (in professional.css)

To change styles, update the CSS link in the HTML files. The refined style is currently active.

### Colors
All colors are defined as CSS variables:
- `--accent-primary`: #60AFC7 (blue)
- `--accent-secondary`: #9B60AA (purple)
- `--accent-coral`: #FE7E57 (coral/orange)
- `--bg-primary`: #0f0f0f (dark background - slightly lighter in refined)

The refined style keeps the same color palette but:
- Reduces glow effects and shadows
- Removes uppercase text transforms
- Softens hover animations
- Makes text more readable
- Keeps the cool tech aesthetic without being overwhelming

### Logo
The logo is created with inline SVG. To use your own logo:
1. Replace the SVG elements with an `<img>` tag
2. Add your logo to an `images/` directory
3. Update the path in both HTML files

### Content
All content is in the HTML files. Simply edit the text, pricing, or features as needed.

## Payment Integration

The pricing page is set up for manual payment processing:
1. **Stripe**: Add your Stripe payment link
2. **PayPal**: Emails will come to your sales email for invoice requests
3. **Wire Transfer**: Same as PayPal

For automated payments, you'll need to:
1. Set up Stripe Checkout or Payment Links
2. Replace the placeholder link with your actual Stripe URL
3. Set up webhook handling on your server for license generation

## License Key Delivery

Currently designed for manual license key delivery:
1. Customer makes payment
2. You receive notification (Stripe, PayPal, etc.)
3. You add their license to `web/license_check.py`
4. You email them their license key

For automation, you'd need a backend service to handle payments and license generation.

## Analytics

To add analytics, insert before closing `</body>` tag:

```html
<!-- Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=YOUR_GA_ID"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'YOUR_GA_ID');
</script>
```

## SEO

Remember to:
1. Update meta descriptions in both HTML files
2. Add Open Graph tags for social sharing
3. Create a sitemap.xml
4. Add robots.txt
5. Set up proper 404 page

## Support

For questions about the static site, contact the development team.