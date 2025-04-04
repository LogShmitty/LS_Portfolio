#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

// Configuration
const IMAGES_DIR = '../images/projects';
const PROJECTS_DIR = '../pages/projects';
const DEFAULT_HERO_IMAGE_INDEX = 0; // Use the first image as hero by default

// Parse command line arguments
const args = process.argv.slice(2);

// Display help message if requested
if (args.includes('--help') || args.includes('-h')) {
    console.log(`
Project Page Generator
======================

This script generates project pages from image folders.

Usage:
  node generate-project-pages.js [options] [folder-name]

Options:
  --help, -h          Show this help message
  --hero=FILENAME     Specify a custom hero image filename
  --all               Process all image folders (default if no folder specified)

Examples:
  node generate-project-pages.js                   # Process all folders
  node generate-project-pages.js Memorii           # Process only the Memorii folder
  node generate-project-pages.js --hero=image.jpg Memorii  # Use specific hero image
    `);
    process.exit(0);
}

// Ensure projects directory exists
if (!fs.existsSync(PROJECTS_DIR)) {
    fs.mkdirSync(PROJECTS_DIR, { recursive: true });
}

// Extract hero image option if provided
let customHeroImage = null;
const heroArg = args.find(arg => arg.startsWith('--hero='));
if (heroArg) {
    customHeroImage = heroArg.substring(7); // Remove '--hero=' prefix
    console.log(`Using custom hero image: ${customHeroImage}`);
    // Remove the hero argument from args
    const heroArgIndex = args.indexOf(heroArg);
    if (heroArgIndex !== -1) {
        args.splice(heroArgIndex, 1);
    }
}

// Check if a specific folder was provided as a command-line argument
// (any remaining argument that doesn't start with --)
const specificFolder = args.find(arg => !arg.startsWith('--'));

if (specificFolder) {
    // Process only the specified folder
    console.log(`Processing specific folder: ${specificFolder}`);
    
    // Check if the folder exists
    const folderPath = path.join(IMAGES_DIR, specificFolder);
    if (fs.existsSync(folderPath) && fs.statSync(folderPath).isDirectory()) {
        processImageFolder(specificFolder);
        console.log(`Processed folder: ${specificFolder}`);
    } else {
        console.error(`Error: Folder "${specificFolder}" not found in ${IMAGES_DIR} directory.`);
        process.exit(1);
    }
} else {
    // Get all directories in the projects folder
    const imageFolders = fs.readdirSync(IMAGES_DIR, { withFileTypes: true })
        .filter(dirent => dirent.isDirectory())
        .map(dirent => dirent.name);

    console.log(`Found ${imageFolders.length} image folders to process.`);

    // Process each folder
    imageFolders.forEach(folderName => {
        processImageFolder(folderName);
    });
}

console.log('Project page generation complete!');

/**
 * Process an image folder and create a project page
 * @param {string} folderName - The name of the image folder
 */
function processImageFolder(folderName) {
    console.log(`Processing folder: ${folderName}`);
    
    // Check if the "selected" subfolder exists
    const folderPath = path.join(IMAGES_DIR, folderName);
    const selectedFolderPath = path.join(folderPath, 'selected');
    
    if (!fs.existsSync(selectedFolderPath) || !fs.statSync(selectedFolderPath).isDirectory()) {
        console.log(`No "selected" subfolder found in ${folderName}, skipping.`);
        return;
    }
    
    // Get all media files in the "selected" subfolder (images and videos)
    const mediaFiles = fs.readdirSync(selectedFolderPath)
        .filter(file => {
            const ext = path.extname(file).toLowerCase();
            return ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.mp4'].includes(ext);
        });
    
    if (mediaFiles.length === 0) {
        console.log(`No media files found in ${folderName}/selected, skipping.`);
        return;
    }
    
    // Create a slug for the project (lowercase, replace spaces with hyphens)
    const projectSlug = folderName.toLowerCase().replace(/\s+/g, '-');
    
    // Filter out just the image files (for hero image selection)
    const imageFiles = mediaFiles.filter(file => {
        const ext = path.extname(file).toLowerCase();
        return ['.jpg', '.jpeg', '.png', '.gif', '.webp'].includes(ext);
    });
    
    if (imageFiles.length === 0) {
        console.log(`No image files found in ${folderName} for hero image, skipping.`);
        return;
    }
    
    // Select a hero image
    let heroImage;
    
    if (customHeroImage && imageFiles.includes(customHeroImage)) {
        // Use the custom hero image if provided and exists in the folder
        heroImage = customHeroImage;
        console.log(`Using custom hero image: ${heroImage}`);
    } else if (customHeroImage) {
        // If custom hero was specified but not found, warn and use default
        console.warn(`Warning: Custom hero image "${customHeroImage}" not found in folder. Using default.`);
        heroImage = imageFiles[DEFAULT_HERO_IMAGE_INDEX];
    } else {
        // Use default (first image)
        heroImage = imageFiles[DEFAULT_HERO_IMAGE_INDEX];
    }
    
    // Create the project page HTML
    const projectHTML = generateProjectHTML(folderName, projectSlug, heroImage, mediaFiles);
    
    // Write the project page to file
    const outputPath = path.join(PROJECTS_DIR, `${projectSlug}.html`);
    fs.writeFileSync(outputPath, projectHTML);
    
    console.log(`Created project page: ${outputPath}`);
}

/**
 * Generate HTML for a project page
 * @param {string} projectName - The name of the project
 * @param {string} projectSlug - The slug for the project
 * @param {string} heroImage - The filename of the hero image
 * @param {string[]} mediaFiles - Array of media filenames (images and videos)
 * @returns {string} The HTML content for the project page
 */
function generateProjectHTML(projectName, projectSlug, heroImage, mediaFiles) {
    // Format the project name for display (remove hyphens, capitalize words)
    const displayName = projectName.replace(/-/g, ' ');
    
    // Check if there's an MP4 file that could be used as a hero video
    const heroVideoFile = mediaFiles.find(file => 
        path.extname(file).toLowerCase() === '.mp4' && 
        file.toLowerCase().includes('hero')
    );
    
    // Create gallery items HTML - limit to first 4 images for template
    const galleryImages = mediaFiles.filter(file => {
        const ext = path.extname(file).toLowerCase();
        return ['.jpg', '.jpeg', '.png', '.gif', '.webp'].includes(ext);
    }).slice(0, 4);
    
    // Create gallery HTML placeholders
    let galleryHTML = '';
    galleryImages.forEach((file, index) => {
        const filePath = `../assets/projects/${projectName}/selected/${file}`;
        galleryHTML += `                <div class="gallery-item">
                    <img src="${filePath}" alt="${displayName} - ${index + 1}">
                </div>\n`;
    });
    
    // If we don't have enough images, add placeholders
    for (let i = galleryImages.length; i < 4; i++) {
        galleryHTML += `                <div class="gallery-item">
                    <img src="[GALLERY_IMAGE_${i + 1}]" alt="[GALLERY_CAPTION_${i + 1}]">
                </div>\n`;
    }
    
    // Determine hero media (video or image)
    const heroMediaPath = heroVideoFile 
        ? `../assets/projects/${projectName}/selected/${heroVideoFile}`
        : `../assets/projects/${projectName}/selected/${heroImage}`;
    
    // Generate the full HTML based on the template
    return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${displayName} | Interactive Nature Studio</title>
    
    <!-- Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    
    <!-- CSS Files -->
    <link rel="stylesheet" href="../css/main.css">
    <link rel="stylesheet" href="../css/components.css">
    <link rel="stylesheet" href="../css/animations.css">
    <link rel="stylesheet" href="../css/responsive.css">
    <link rel="stylesheet" href="../css/project.css">
</head>
<body>
    <div class="cursor"></div>
    
    <svg class="bg-lines" width="100%" height="100%" preserveAspectRatio="none">
        <!-- Lines will be generated by JS -->
    </svg>
    
    <!-- SVG Definitions for gradients -->
    <svg width="0" height="0" style="position: absolute;">
        <defs>
            <linearGradient id="iridescent-gradient" x1="0%" y1="0%" x2="100%" y2="0%">
                <stop offset="0%" stop-color="#C4D4DB" />
                <stop offset="25%" stop-color="#9AC2C9" />
                <stop offset="50%" stop-color="#B19CD9" />
                <stop offset="75%" stop-color="#93B5C6" />
                <stop offset="100%" stop-color="#BFD8BD" />
            </linearGradient>
        </defs>
    </svg>
    
    <header>
        <div class="logo">
            <a href="../index.html">
              <img src="../assets/images/InteractiveNatureLogo.png" alt="Interactive Nature Logo">
            </a>
          </div>
        <nav>
            <ul>
                <li><a href="../index.html#services">Services</a></li>
                <li><a href="../index.html#work">Work</a></li>
                <li><a href="../index.html#about">About</a></li>
                <li><a href="../index.html#contact">Contact</a></li>
            </ul>
        </nav>
    </header>

    <!-- Hero Section with Project Title -->
    <section class="project-hero">
        <div class="project-hero-media">
            ${heroVideoFile 
                ? `<!-- Project video -->
            <video autoplay muted loop>
                <source src="${heroMediaPath}" type="video/mp4">
            </video>`
                : `<!-- Project image -->
            <img src="${heroMediaPath}" alt="${displayName}">`
            }
            
            <!-- Overlay with gradient for better text visibility -->
            <div class="hero-overlay"></div>
        </div>
        <div class="project-hero-content">
            <h1>${displayName}</h1>
            <p class="project-subtitle">Interactive Experience</p>
        </div>
    </section>

    <!-- Project Overview Section -->
    <section class="project-overview">
        <div class="container">
            <div class="project-info">
                <div class="project-info-left">
                    <h2>Project Overview</h2>
                    <p>This is an automatically generated project page for ${displayName}. Please update this description with details about the project.</p>
                    <p>You can add multiple paragraphs to describe the project's concept, goals, and outcomes.</p>
                </div>
                <div class="project-info-right">
                    <div class="project-meta">
                        <div class="meta-item">
                            <h3>Client</h3>
                            <p>Client Name</p>
                        </div>
                        <div class="meta-item">
                            <h3>Year</h3>
                            <p>2025</p>
                        </div>
                        <div class="meta-item">
                            <h3>Services</h3>
                            <p>Interactive Installation</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- Project Gallery Section -->
    <section class="project-gallery">
        <div class="container">
            <h2>Gallery</h2>
            <div class="gallery-grid">
                <!-- Gallery images -->
${galleryHTML}
            </div>
        </div>
    </section>

    <!-- Next Project Section -->
    <section class="next-project">
        <div class="container">
            <h2>Next Project</h2>
            <a href="#" class="next-project-link">
                <div class="next-project-preview">
                    <img src="../assets/images/portfolio/lightForest.jpg" alt="Next Project">
                    <div class="next-project-overlay">
                        <h3>Next Project</h3>
                        <span class="next-arrow">→</span>
                    </div>
                </div>
            </a>
        </div>
    </section>

    <footer>
        <div class="container">
            <div class="footer-links">
                <a href="../index.html#services">Services</a>
                <a href="../index.html#work">Work</a>
                <a href="../index.html#about">About</a>
                <a href="../index.html#contact">Contact</a>
            </div>
            <p>&copy; 2025 Interactive Nature Studio. All rights reserved.</p>
        </div>
    </footer>

    <!-- JavaScript Files -->
    <script type="module" src="../js/main.js"></script>
    <script type="module" src="../js/project.js"></script>
</body>
</html>`;
}

// Navigation menu function removed as per requirements
