document.addEventListener('DOMContentLoaded', function() {
    const notifications = document.querySelectorAll('.notificationContainer[data-timeout]');

    notifications.forEach(notification => {
        const timeout = parseInt(notification.getAttribute('data-timeout')) || 5000;

        // Close button handler
        const closeBtn = notification.querySelector('.close');
        if (closeBtn) {
            closeBtn.addEventListener('click', () => {
                notification.style.opacity = '0';
                setTimeout(() => notification.remove(), 300);
            });
        }

        // Auto-dismiss
        setTimeout(() => {
            notification.style.opacity = '0';
            setTimeout(() => notification.remove(), 300);
        }, timeout);
    });
});
