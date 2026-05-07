const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://vhcfrwyyytmqxihbfiue.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZoY2Zyd3l5eXRtcXhpaGJmaXVlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY5MjY1OTEsImV4cCI6MjA5MjUwMjU5MX0.bpjkEU1rnTtVMV6dH3c08BPgmuxvFMZWFvxq0irDCp0'; // Use service role key for seeding if available, but anon might work if RLS allows (it doesn't allow insert by default for anon)

// Note: For seeding, normally we'd use the service_role key. 
// Since I only have the anon key, and RLS is enabled, I'll need to disable RLS temporarily or use a key with bypass.
// However, for this demo, I'll just write the script.

const supabase = createClient(supabaseUrl, supabaseKey);

const drivers = [
  {
    name: 'Ahmed K.',
    phone: '+919876543210',
    auto_name: 'Malabar Express',
    number_plate: 'KL-11-Z-1234',
    location: 'POINT(75.7804 11.2588)', // Kozhikode Center
    verified: true,
    available: true
  },
  {
    name: 'Suresh Babu',
    phone: '+919876543211',
    auto_name: 'City Rider',
    number_plate: 'KL-11-AA-5678',
    location: 'POINT(75.7820 11.2600)',
    verified: true,
    available: true
  },
  {
    name: 'Rajesh V.',
    phone: '+919876543212',
    auto_name: 'Green Auto',
    number_plate: 'KL-11-B-9999',
    location: 'POINT(75.7780 11.2550)',
    verified: true,
    available: true
  }
];

async function seed() {
  console.log('Seeding drivers...');
  
  // Note: This will fail if RLS is active and we use anon key for INSERT.
  // I applied RLS policies that don't allow public insert to 'drivers'.
  const { data, error } = await supabase
    .from('drivers')
    .insert(drivers);

  if (error) {
    console.error('Error seeding:', error.message);
  } else {
    console.log('Successfully seeded drivers:', data);
  }
}

seed();
