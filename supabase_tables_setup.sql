-- Create users table
CREATE TABLE public.users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  plan TEXT NOT NULL DEFAULT 'free',
  points INTEGER NOT NULL DEFAULT 300
);

-- Create projects table
CREATE TABLE public.projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Create plot_data table
CREATE TABLE public.plot_data (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  content TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Enable Row Level Security (RLS) on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plot_data ENABLE ROW LEVEL SECURITY;

-- RLS policies for users table
CREATE POLICY "Users can view own user data" ON public.users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own data" ON public.users
  FOR UPDATE USING (auth.uid() = id);

-- RLS policies for projects table
CREATE POLICY "Users can view own projects" ON public.projects
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own projects" ON public.projects
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own projects" ON public.projects
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own projects" ON public.projects
  FOR DELETE USING (auth.uid() = user_id);

-- RLS policies for plot_data table
CREATE POLICY "Users can view own plot data" ON public.plot_data
  FOR SELECT USING (
    auth.uid() IN (
      SELECT user_id FROM public.projects WHERE id = plot_data.project_id
    )
  );

CREATE POLICY "Users can create own plot data" ON public.plot_data
  FOR INSERT WITH CHECK (
    auth.uid() IN (
      SELECT user_id FROM public.projects WHERE id = plot_data.project_id
    )
  );

CREATE POLICY "Users can update own plot data" ON public.plot_data
  FOR UPDATE USING (
    auth.uid() IN (
      SELECT user_id FROM public.projects WHERE id = plot_data.project_id
    )
  );

CREATE POLICY "Users can delete own plot data" ON public.plot_data
  FOR DELETE USING (
    auth.uid() IN (
      SELECT user_id FROM public.projects WHERE id = plot_data.project_id
    )
  );

-- Create indexes for better query performance
CREATE INDEX idx_projects_user_id ON public.projects(user_id);
CREATE INDEX idx_plot_data_project_id ON public.plot_data(project_id);
CREATE INDEX idx_plot_data_type ON public.plot_data(type);
