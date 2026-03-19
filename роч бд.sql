-- 1. Создание перечислений (ENUM) для статусов и ролей
-- Поддерживает логику статусов из US 1, 2, 5, 8, 9
CREATE TYPE user_role AS ENUM ('store_manager', 'office_manager', 'hr_specialist');

CREATE TYPE task_status AS ENUM (
    'new',          -- US 1: После сохранения статус «новый»
    'in_progress',  -- US 2: После отправки статус «в работе»
    'assigned',     -- US 5: Назначены специалисты (ожидание выполнения)
    'closed',       -- US 9: Задание закрыто
    'cancelled'     -- US 8: Задание отменено
);

CREATE TYPE recruitment_status AS ENUM (
    'open',         -- Заявка активна
    'filled',       -- Кандидат найден
    'closed'        -- Заявка закрыта
);

-- 2. Таблица пользователей (Системные роли: Управляющий магазином, Офисом, HR)
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role user_role NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- 3. Таблица магазинов
-- Связь с Управляющим магазином
CREATE TABLE stores (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    address TEXT,
    manager_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 4. Таблица специалистов (База «Персонал»)
-- US 4: Поиск специалистов
-- US 10: Добавление в базу
CREATE TABLE specialists (
    id SERIAL PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    contact_info TEXT,
    skills TEXT[], -- Массив навыков для фильтрации (US 4)
    is_available BOOLEAN DEFAULT TRUE,
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL, -- Связь, если специалист получит доступ к системе
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 5. Таблица заданий (Сервисные работы)
-- US 1: Поля наименования, дат, требований
-- US 2, 5, 8, 9: Статусы
CREATE TABLE tasks (
    id SERIAL PRIMARY KEY,
    store_id INTEGER NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL, -- Наименование работ
    description TEXT,
    requirements TEXT, -- Требования к исполнителям
    date_start DATE NOT NULL,
    date_end DATE NOT NULL,
    status task_status DEFAULT 'new',
    created_by INTEGER NOT NULL REFERENCES users(id), -- Управляющий магазином
    office_manager_id INTEGER REFERENCES users(id), -- Управляющий офисом (кто взял в работу)
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 6. Связь Задания и Специалистов (Многие-ко-многим)
-- US 5: Назначение специалистов
-- Позволяет назначить несколько исполнителей на одно задание
CREATE TABLE task_assignments (
    task_id INTEGER NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    specialist_id INTEGER NOT NULL REFERENCES specialists(id) ON DELETE CASCADE,
    assigned_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    assigned_by INTEGER REFERENCES users(id), -- Кто назначил (Офис-менеджер)
    PRIMARY KEY (task_id, specialist_id)
);

-- 7. Таблица заявок на подбор (HR)
-- US 6: Заявка создается из задания
-- US 7: Список заявок для HR
CREATE TABLE recruitment_requests (
    id SERIAL PRIMARY KEY,
    task_id INTEGER NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    hr_id INTEGER REFERENCES users(id), -- Ответственный HR
    status recruitment_status DEFAULT 'open',
    description TEXT, -- Комментарий, почему нужны люди
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMPTZ
);

-- 8. Таблица истории изменений и уведомлений
-- US 11: Уведомления о смене статуса
-- Позволяет триггерам или приложению записывать события для рассылки
CREATE TABLE task_events (
    id SERIAL PRIMARY KEY,
    task_id INTEGER NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id), -- Кто инициировал
    event_type VARCHAR(50) NOT NULL, -- Например: 'status_change', 'assignment', 'comment'
    old_value VARCHAR(255),
    new_value VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 9. Таблица уведомлений (Для US 11)
CREATE TABLE notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- === ИНДЕКСЫ ДЛЯ ПРОИЗВОДИТЕЛЬНОСТИ ===

-- US 3: Фильтрация заданий по статусу и дате
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_dates ON tasks(date_start, date_end);
CREATE INDEX idx_tasks_store ON tasks(store_id);

-- US 4: Поиск специалистов по навыкам (GIN индекс для массивов)
CREATE INDEX idx_specialists_skills ON specialists USING GIN (skills);

-- US 7: Поиск заявок по статусу
CREATE INDEX idx_recruitment_status ON recruitment_requests(status);

-- Связи
CREATE INDEX idx_task_assignments_task ON task_assignments(task_id);
CREATE INDEX idx_task_assignments_specialist ON task_assignments(specialist_id);

