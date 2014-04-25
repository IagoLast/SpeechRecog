package es.udc.iagolast.speechrecog.speechrecog.adapters;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.ImageView;
import android.widget.TextView;

import java.util.List;

import es.udc.iagolast.speechrecog.speechrecog.R;
import es.udc.iagolast.speechrecog.speechrecog.voicetivities.Voicetivity;

/**
 * Created by iagolast on 24/04/14.
 */
public class VtAdapter extends BaseAdapter {
    private Context context;
    private List<Voicetivity> voicetivityList;

    public VtAdapter(Context context, List<Voicetivity> voicetivityList) {
        this.context = context;
        this.voicetivityList = voicetivityList;
    }

    @Override
    public int getCount() {
        return voicetivityList.size();
    }

    @Override
    public Voicetivity getItem(int position) {
        return voicetivityList.get(position);
    }

    @Override
    public long getItemId(int position) {
        return position; //TODO: voicetivities shoud have id;
    }

    @Override
    public View getView(int position, View convertView, ViewGroup parent) {
        LayoutInflater inflater = (LayoutInflater) context
                .getSystemService(Context.LAYOUT_INFLATER_SERVICE);

        View rowView = inflater.inflate(R.layout.item_voicetivity, parent, false);

        ImageView imageView = (ImageView) rowView.findViewById(R.id.imageView);
        TextView textViewName = (TextView) rowView.findViewById(R.id.tvVoicetivityName);
        TextView textViewDesc = (TextView) rowView.findViewById(R.id.tvVoicetivityDesc);


        String imageName = voicetivityList.get(position).getIconName();
        imageView.setImageResource(context.getResources().getIdentifier(imageName, "drawable", context.getPackageName()));
        textViewName.setText(voicetivityList.get(position).getName());
        textViewDesc.setText(voicetivityList.get(position).getDesc());

        return rowView;
    }

}
