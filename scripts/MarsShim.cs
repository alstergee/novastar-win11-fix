// MarsShim - Creates the IPC window that SmartLCT expects
// Compile: csc /target:winexe MarsShim.cs
using System;
using System.Windows.Forms;
using System.Runtime.InteropServices;
using System.IO.MemoryMappedFiles;

class MarsShim : Form
{
    const string WINDOW_NAME = "A7F89E4D-04F4-46a6-9754-A334B3E8FEE5";
    const string SHARED_MEM_NAME = "LedInfo";
    const long SHARED_MEM_SIZE = 104857600 + 130; // Same as Mars

    MemoryMappedFile _sharedMem;

    [DllImport("user32.dll")]
    static extern bool ChangeWindowMessageFilterEx(IntPtr hwnd, uint message, uint action, IntPtr changeFilterStruct);

    const uint WM_COPYDATA = 0x004A;
    const uint MSGFLT_ALLOW = 1;

    public MarsShim()
    {
        this.Text = WINDOW_NAME;
        this.ShowInTaskbar = false;
        this.Opacity = 0;
        this.FormBorderStyle = FormBorderStyle.FixedToolWindow;
        this.StartPosition = FormStartPosition.Manual;
        this.Location = new System.Drawing.Point(-1000, -1000);
        this.Size = new System.Drawing.Size(1, 1);
    }

    protected override void OnLoad(EventArgs e)
    {
        base.OnLoad(e);

        // Allow WM_COPYDATA through UIPI
        ChangeWindowMessageFilterEx(this.Handle, WM_COPYDATA, MSGFLT_ALLOW, IntPtr.Zero);

        // Create shared memory
        try
        {
            _sharedMem = MemoryMappedFile.CreateOrOpen(SHARED_MEM_NAME, SHARED_MEM_SIZE);
            Console.WriteLine("[MarsShim] Created shared memory: " + SHARED_MEM_NAME);
        }
        catch (Exception ex)
        {
            Console.WriteLine("[MarsShim] Shared memory error: " + ex.Message);
        }

        Console.WriteLine("[MarsShim] Window created: " + this.Text);
        Console.WriteLine("[MarsShim] Handle: " + this.Handle);
        Console.WriteLine("[MarsShim] Waiting for messages... (Ctrl+C to exit)");
    }

    protected override void WndProc(ref Message m)
    {
        if (m.Msg == WM_COPYDATA)
        {
            Console.WriteLine("[MarsShim] Received WM_COPYDATA from: " + m.WParam);
            // For now just acknowledge receipt
        }
        base.WndProc(ref m);
    }

    protected override void OnFormClosing(FormClosingEventArgs e)
    {
        if (_sharedMem != null) _sharedMem.Dispose();
        base.OnFormClosing(e);
    }

    [STAThread]
    static void Main()
    {
        Console.WriteLine("[MarsShim] Starting Mars IPC Shim...");
        Application.EnableVisualStyles();
        Application.Run(new MarsShim());
    }
}
