# Table Tennis Scoreboard

This is the source for my [Table Tennis Scoreboard](https://tabletennisscoreboard.com)
website. It uses [eleventy](https://www.11ty.dev/) as a
static site generator, [Tailwind](http://tailwindcss.com/) for styling, 
[AlpineJS](https://alpinejs.dev/) for all the state management and game logic,
and is hosted on [Netlify](https://www.netlify.com/).

Go [have a play](https://tabletennisscoreboard.com) or [read
about the functionality](https://tabletennisscoreboard.com/help).

## Kiosk Display Deployment

This repository includes a specialized deployment configuration for running the scoreboard on dedicated kiosk displays, optimized for Raspberry Pi Zero 2W with Waveshare 5" LCD displays:

### 🖥️ [DietPi Deployment](./table-tennis-scoreboard-dietpi/)
**Complete local hosting solution**
- Lightweight Debian-based OS
- Full control and customization
- SSH access and command-line management
- Optimized for Pi Zero 2W performance
- Includes automated deployment script
- Self-contained with no external dependencies

### Hardware Requirements

The DietPi deployment is optimized for:
- **Raspberry Pi Zero 2W** (recommended)
- **Waveshare 5" LCD Display** (800x480)
- **8GB+ MicroSD Card** (Class 10)
- **Stable WiFi Connection**

### Getting Started

1. **Follow the setup guide** in the [DietPi deployment directory](./table-tennis-scoreboard-dietpi/)
2. **Use the provided configuration templates** for quick setup
3. **Run the automated deployment script** for easy installation

The deployment directory contains:
- 📖 Comprehensive setup guide
- ⚙️ Configuration templates
- 🔧 Management scripts
- 🛠️ Troubleshooting guides

## Development

### Local Development

To run the scoreboard locally for development:

```bash
# Install dependencies
npm install

# Start development server
npm run dev
```

The development server will start at `http://localhost:8080` with hot reloading enabled.

### Building for Production

```bash
# Build the static site
npm run build
```

The built files will be in the `_site` directory, ready for deployment to any static hosting service.

### Project Structure

```
├── src/                    # Source files
│   ├── _includes/         # Eleventy templates and layouts
│   ├── assets/           # CSS, JS, and other assets
│   └── *.md              # Content pages
├── table-tennis-scoreboard-dietpi/     # DietPi deployment
├── .eleventy.js          # Eleventy configuration
├── tailwind.config.js    # Tailwind CSS configuration
└── package.json          # Dependencies and scripts
```

### Technologies Used

- **[Eleventy](https://www.11ty.dev/)** - Static site generator
- **[Tailwind CSS](https://tailwindcss.com/)** - Utility-first CSS framework
- **[Alpine.js](https://alpinejs.dev/)** - Lightweight JavaScript framework
- **[Netlify](https://www.netlify.com/)** - Hosting and deployment

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Areas for Contribution

- 🐛 Bug fixes and improvements
- 🎨 UI/UX enhancements
- 🖥️ DietPi deployment enhancements
- 📱 Mobile responsiveness improvements
- 🌐 Internationalization
- 📊 Analytics and statistics features

## License

This project is open source and available under the [MIT License](LICENSE).


