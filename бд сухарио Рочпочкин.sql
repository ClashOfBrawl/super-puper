
CREATE TYPE user_role AS ENUM (
    'store_manager',      
    'office_manager',    
    'specialist'        
);


CREATE TYPE task_status AS ENUM (
    'new',                
    'in_progress',        
    'assigned',           
    'completed',         
    'cancelled'          
);


CREATE TABLE stores (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    address TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);


CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role user_role NOT NULL,
    store_id BIGINT REFERENCES stores(id) ON DELETE SET NULL, -- Для управляющих магазином
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);


CREATE TABLE tasks (
    id BIGSERIAL PRIMARY KEY,
    store_id BIGINT NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    created_by BIGINT NOT NULL REFERENCES users(id), 
    
    title VARCHAR(255) NOT NULL,            
    description TEXT,                     
    requirements TEXT,                     
    
    work_type VARCHAR(100),                  
    planned_date_start DATE NOT NULL,        
    planned_date_end DATE NOT NULL,
    
    status task_status DEFAULT 'new',       
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    submitted_at TIMESTAMP WITH TIME ZONE   
);

CREATE TABLE task_assignments (
    id BIGSERIAL PRIMARY KEY,
    task_id BIGINT NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    specialist_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    assigned_by BIGINT REFERENCES users(id),
    
    UNIQUE (task_id, specialist_id) 
);


CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_work_type ON tasks(work_type);
CREATE INDEX idx_tasks_dates ON tasks(planned_date_start, planned_date_end);
CREATE INDEX idx_users_role ON users(role);
INSERT INTO tasks (store_id, created_by, title, requirements, planned_date_start, planned_date_end, work_type)
VALUES (1, 101, 'Ремонт кондиционера', 'Нужен допуск к высоте', '2023-10-01', '2023-10-02', 'HVAC');
UPDATE tasks 
SET status = 'in_progress', 
    submitted_at = NOW(),
    updated_at = NOW()
WHERE id = 1;
SELECT id, title, work_type, planned_date_start 
FROM tasks 
WHERE status = 'in_progress'
  AND work_type = 'HVAC'  
  AND planned_date_start >= '2023-10-01'; 
  INSERT INTO task_assignments (task_id, specialist_id, assigned_by)
VALUES (1, 505, 202);