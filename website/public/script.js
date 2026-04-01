/* 
    GAMES PLATFORM - Script
    Adding interactivity and scroll animations
*/

document.addEventListener('DOMContentLoaded', () => {
    // 1. Initial AOS (Animate On Scroll) setup
    const aosElements = document.querySelectorAll('[data-aos]');
    
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('active');
            }
        });
    }, observerOptions);

    aosElements.forEach(el => {
        observer.observe(el);
    });

    // 2. Smooth Scrolling for internal links
    const scrollLinks = document.querySelectorAll('a[href^="#"]');
    scrollLinks.forEach(link => {
        link.addEventListener('click', (e) => {
            e.preventDefault();
            const targetId = link.getAttribute('href');
            const targetElement = document.querySelector(targetId);
            
            if (targetElement) {
                window.scrollTo({
                    top: targetElement.offsetTop - 100, // Adjust for navbar height
                    behavior: 'smooth'
                });
            }
        });
    });

    // 3. Simple blob movement on mouse move (Desktop only)
    if (window.innerWidth > 1024) {
        document.addEventListener('mousemove', (e) => {
            const x = e.clientX / window.innerWidth;
            const y = e.clientY / window.innerHeight;
            
            const blob1 = document.querySelector('.blob-1');
            const blob2 = document.querySelector('.blob-2');
            
            if (blob1) blob1.style.transform = `translate(${x * 30}px, ${y * 30}px)`;
            if (blob2) blob2.style.transform = `translate(${x * -30}px, ${y * -30}px)`;
        });
    }

    // 4. Hamburger Menu Logic
    const hamburger = document.querySelector('.hamburger');
    const nav = document.querySelector('nav');
    const navLinks = document.querySelectorAll('nav a');

    if (hamburger && nav) {
        hamburger.addEventListener('click', () => {
            nav.classList.toggle('active');
            hamburger.classList.toggle('open');
        });

        // Close menu when a link is clicked
        navLinks.forEach(link => {
            link.addEventListener('click', () => {
                nav.classList.remove('active');
                hamburger.classList.remove('open');
            });
        });
    }

    // 5. Console greeting for developers
    console.log("%cمنصة الألعاب 🎮%c جاهزة للاستخدام!", "color: #3B82F6; font-size: 20px; font-weight: bold;", "color: grey; font-size: 14px;");
});

